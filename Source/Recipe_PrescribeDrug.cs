using System.Collections.Generic;
using RimWorld;
using Verse;

namespace Narcotics
{
    public class Recipe_PrescribeDrug : Recipe_Surgery
    {
        public override void ApplyOnPawn(Pawn pawn, BodyPartRecord part, Pawn billDoer, List<Thing> ingredients, Bill bill)
        {
            PrescriptionExtension ext = recipe.GetModExtension<PrescriptionExtension>();
            if (ext == null || ext.drugDef == null || ext.prescriptionHediff == null)
            {
                Log.Error("[Narcotics] Prescribe recipe missing PrescriptionExtension: " + recipe.defName);
                return;
            }

            if (CheckSurgeryFail(billDoer, pawn, ingredients, part, bill))
            {
                return;
            }

            // Remove any existing prescription for the same drug so courses don't stack forever.
            List<Hediff> hediffs = pawn.health.hediffSet.hediffs;
            for (int i = hediffs.Count - 1; i >= 0; i--)
            {
                HediffComp_DrugPrescription comp = hediffs[i].TryGetComp<HediffComp_DrugPrescription>();
                if (comp != null && comp.Props.drugDef == ext.drugDef)
                {
                    pawn.health.RemoveHediff(hediffs[i]);
                }
            }

            Hediff hediff = HediffMaker.MakeHediff(ext.prescriptionHediff, pawn);
            hediff.Severity = ext.days;
            pawn.health.AddHediff(hediff);

            // First dose: apply ingest outcomes from the prescribed drug ingredient if present.
            Thing dose = null;
            if (ingredients != null)
            {
                for (int i = 0; i < ingredients.Count; i++)
                {
                    if (ingredients[i] != null && ingredients[i].def == ext.drugDef)
                    {
                        dose = ingredients[i];
                        break;
                    }
                }
            }

            // First dose: apply ingest outcomes from one unit of the prescribed drug.
            // SplitOff so the bill can still consume remaining ingredient stacks cleanly.
            if (dose != null && dose.def.ingestible != null)
            {
                Thing one = dose.SplitOff(1);
                one.Ingested(pawn, 0f);
            }

            if (billDoer != null)
            {
                TaleRecorder.RecordTale(TaleDefOf.DidSurgery, billDoer, pawn);
            }

            Messages.Message(
                "Narcotics_PrescriptionStarted".Translate(
                    billDoer?.LabelShort ?? "doctor",
                    pawn.LabelShort,
                    ext.drugDef.label,
                    ext.days),
                pawn,
                MessageTypeDefOf.PositiveEvent);
        }

        public override string GetLabelWhenUsedOn(Pawn pawn, BodyPartRecord part)
        {
            PrescriptionExtension ext = recipe.GetModExtension<PrescriptionExtension>();
            if (ext?.drugDef == null)
            {
                return base.GetLabelWhenUsedOn(pawn, part);
            }

            return "Narcotics_PrescribeLabel".Translate(ext.drugDef.label, ext.days);
        }
    }
}
