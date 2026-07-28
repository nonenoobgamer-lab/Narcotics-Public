using System.Collections.Generic;
using RimWorld;
using UnityEngine;
using Verse;
using Verse.AI;

namespace Narcotics
{
    public class JobGiver_BuyDrugFromDealer : ThinkNode_JobGiver
    {
        private const float CriticalNeed = 0.25f;
        // Just under JobGiver_SatisfyChemicalNeed (~9.25) so colony stock is tried first.
        private const float PriorityWhenNeeded = 9.15f;

        public override float GetPriority(Pawn pawn)
        {
            return FindNeededDrug(pawn) != null ? PriorityWhenNeeded : 0f;
        }

        protected override Job TryGiveJob(Pawn pawn)
        {
            if (pawn?.Map == null || !pawn.Spawned || pawn.Downed || pawn.InMentalState || pawn.Drafted)
            {
                return null;
            }

            ThingDef drugDef = FindNeededDrug(pawn);
            if (drugDef == null)
            {
                return null;
            }

            if (!FindDealerAndDrug(pawn, drugDef, out Pawn dealer, out Thing drugThing))
            {
                return null;
            }

            int price = Mathf.Max(1, Mathf.RoundToInt(drugDef.BaseMarketValue));
            if (!HasEnoughSilver(pawn.Map, price))
            {
                return null;
            }

            Job job = JobMaker.MakeJob(
                DefDatabase<JobDef>.GetNamed("Narcotics_BuyDrugFromDealer"),
                dealer,
                drugThing);
            job.count = 1;
            return job;
        }

        private static ThingDef FindNeededDrug(Pawn pawn)
        {
            if (pawn?.health?.hediffSet?.hediffs == null || pawn.Map == null)
            {
                return null;
            }

            List<Hediff> hediffs = pawn.health.hediffSet.hediffs;
            for (int i = 0; i < hediffs.Count; i++)
            {
                if (!(hediffs[i] is Hediff_Addiction addiction))
                {
                    continue;
                }

                ChemicalDef chemical = addiction.Chemical;
                if (!NarcoticsDrugUtility.IsNarcoticsChemical(chemical))
                {
                    continue;
                }

                Need need = addiction.Need;
                if (need == null || need.CurLevel >= CriticalNeed)
                {
                    continue;
                }

                ThingDef candidate = NarcoticsDrugUtility.DrugForChemical(chemical);
                if (candidate == null || ColonyHasReachableDrug(pawn, candidate))
                {
                    continue;
                }

                return candidate;
            }

            return null;
        }

        private static bool ColonyHasReachableDrug(Pawn pawn, ThingDef drugDef)
        {
            if (pawn.inventory != null)
            {
                List<Thing> inv = pawn.inventory.innerContainer.InnerListForReading;
                for (int i = 0; i < inv.Count; i++)
                {
                    if (inv[i].def == drugDef && inv[i].IngestibleNow)
                    {
                        return true;
                    }
                }
            }

            Thing found = GenClosest.ClosestThingReachable(
                pawn.Position,
                pawn.Map,
                ThingRequest.ForDef(drugDef),
                PathEndMode.ClosestTouch,
                TraverseParms.For(pawn),
                9999f,
                t => !t.IsForbidden(pawn) && t.IngestibleNow);
            return found != null;
        }

        private static bool FindDealerAndDrug(Pawn buyer, ThingDef drugDef, out Pawn dealer, out Thing drugThing)
        {
            dealer = null;
            drugThing = null;
            float bestDist = float.MaxValue;
            IReadOnlyList<Pawn> pawns = buyer.Map.mapPawns.AllPawnsSpawned;
            for (int i = 0; i < pawns.Count; i++)
            {
                Pawn p = pawns[i];
                if (p.Faction == Faction.OfPlayer || p.Dead || p.Downed || !p.CanTradeNow)
                {
                    continue;
                }

                if (!(p is ITrader))
                {
                    continue;
                }

                if (!buyer.CanReach(p, PathEndMode.Touch, Danger.Deadly))
                {
                    continue;
                }

                Thing found = FindDrugInTraderGoods(p, drugDef);
                if (found == null)
                {
                    continue;
                }

                float dist = buyer.Position.DistanceToSquared(p.Position);
                if (dist < bestDist)
                {
                    bestDist = dist;
                    dealer = p;
                    drugThing = found;
                }
            }

            return dealer != null && drugThing != null;
        }

        private static Thing FindDrugInTraderGoods(Pawn trader, ThingDef drugDef)
        {
            ITrader it = trader;
            foreach (Thing t in it.Goods)
            {
                if (t != null && t.def == drugDef && t.stackCount > 0 && !t.Destroyed)
                {
                    return t;
                }
            }

            return null;
        }

        private static bool HasEnoughSilver(Map map, int price)
        {
            int total = 0;
            List<Thing> silver = map.listerThings.ThingsOfDef(ThingDefOf.Silver);
            for (int i = 0; i < silver.Count; i++)
            {
                if (!silver[i].IsForbidden(Faction.OfPlayer))
                {
                    total += silver[i].stackCount;
                    if (total >= price)
                    {
                        return true;
                    }
                }
            }

            return false;
        }
    }
}
