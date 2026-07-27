using System.Collections.Generic;
using RimWorld;
using Verse;
using Verse.AI;

namespace Narcotics
{
    public class HediffComp_DrugPrescription : HediffComp
    {
        private int lastDoseDay = -99999;
        private bool warnedMissingDose;

        public HediffCompProperties_DrugPrescription Props =>
            (HediffCompProperties_DrugPrescription)props;

        public override void CompExposeData()
        {
            base.CompExposeData();
            Scribe_Values.Look(ref lastDoseDay, "lastDoseDay", -99999);
            Scribe_Values.Look(ref warnedMissingDose, "warnedMissingDose", false);
        }

        public override void CompPostPostAdd(DamageInfo? dinfo)
        {
            base.CompPostPostAdd(dinfo);
            // First dose is administered during the prescribe operation.
            lastDoseDay = GenDate.DaysPassed;
            warnedMissingDose = false;
        }

        public override void CompPostTick(ref float severityAdjustment)
        {
            base.CompPostTick(ref severityAdjustment);
            Pawn pawn = parent.pawn;
            if (pawn == null || !pawn.Spawned || pawn.Dead || Props.drugDef == null)
            {
                return;
            }

            // Severity drains via HediffCompProperties_SeverityPerDay on the hediff.
            if (parent.Severity <= 0.01f)
            {
                return;
            }

            int day = GenDate.DaysPassed;
            if (day <= lastDoseDay)
            {
                return;
            }

            // Only auto-dose once the first full day after the operation has passed.
            if (parent.ageTicks < GenDate.TicksPerDay)
            {
                return;
            }

            if (TryTakeDailyDose(pawn))
            {
                lastDoseDay = day;
                warnedMissingDose = false;
            }
            else if (!warnedMissingDose && pawn.IsColonistPlayerControlled)
            {
                warnedMissingDose = true;
                Messages.Message(
                    "Narcotics_MissingPrescriptionDose".Translate(pawn.LabelShort, Props.drugDef.label),
                    pawn,
                    MessageTypeDefOf.NegativeEvent);
            }
        }

        public override string CompTipStringExtra
        {
            get
            {
                if (Props.drugDef == null)
                {
                    return null;
                }

                int daysLeft = (int)parent.Severity;
                if (daysLeft < 1)
                {
                    daysLeft = 1;
                }

                return "Narcotics_PrescriptionTip".Translate(Props.drugDef.label, daysLeft);
            }
        }

        private bool TryTakeDailyDose(Pawn pawn)
        {
            Thing drug = FindDrugFor(pawn);
            if (drug == null)
            {
                return false;
            }

            // Prefer a normal ingest job so animation / outcomes match vanilla.
            if (pawn.CurJobDef == JobDefOf.Ingest && pawn.CurJob?.targetA.Thing?.def == Props.drugDef)
            {
                lastDoseDay = GenDate.DaysPassed;
                return true;
            }

            if (pawn.Downed || pawn.InMentalState)
            {
                // Directly apply ingest effects if they cannot walk to it and it's in inventory.
                if (pawn.inventory != null && pawn.inventory.innerContainer.Contains(drug))
                {
                    ApplyIngestEffects(pawn, drug);
                    if (drug.stackCount <= 0 && !drug.Destroyed)
                    {
                        drug.Destroy();
                    }

                    return true;
                }

                return false;
            }

            Job job = JobMaker.MakeJob(JobDefOf.Ingest, drug);
            job.count = 1;
            return pawn.jobs.TryTakeOrderedJob(job, JobTag.SatisfyingNeeds);
        }

        private Thing FindDrugFor(Pawn pawn)
        {
            ThingDef def = Props.drugDef;
            if (def == null)
            {
                return null;
            }

            if (pawn.inventory != null)
            {
                List<Thing> inv = pawn.inventory.innerContainer.InnerListForReading;
                for (int i = 0; i < inv.Count; i++)
                {
                    if (inv[i].def == def && inv[i].IngestibleNow)
                    {
                        return inv[i];
                    }
                }
            }

            if (pawn.Map == null)
            {
                return null;
            }

            return GenClosest.ClosestThingReachable(
                pawn.Position,
                pawn.Map,
                ThingRequest.ForDef(def),
                PathEndMode.ClosestTouch,
                TraverseParms.For(pawn),
                9999f,
                t => !t.IsForbidden(pawn) && pawn.CanReserve(t) && t.IngestibleNow && t.def == def);
        }

        private static void ApplyIngestEffects(Pawn pawn, Thing drug)
        {
            int ingested = 1;
            if (drug.def.ingestible != null)
            {
                drug.Ingested(pawn, 0f);
                if (drug.stackCount > 0)
                {
                    drug.SplitOff(ingested)?.Destroy();
                }
            }
        }
    }
}
