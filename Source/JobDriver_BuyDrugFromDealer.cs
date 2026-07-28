using System.Collections.Generic;
using RimWorld;
using UnityEngine;
using Verse;
using Verse.AI;

namespace Narcotics
{
    public class JobDriver_BuyDrugFromDealer : JobDriver
    {
        private Pawn Dealer => (Pawn)job.GetTarget(TargetIndex.A).Thing;
        private Thing DrugStack => job.GetTarget(TargetIndex.B).Thing;

        public override bool TryMakePreToilReservations(bool errorOnFailed)
        {
            return pawn.Reserve(Dealer, job, 1, -1, null, errorOnFailed);
        }

        protected override IEnumerable<Toil> MakeNewToils()
        {
            this.FailOnDespawnedNullOrForbidden(TargetIndex.A);
            this.FailOn(() => Dealer == null || !Dealer.CanTradeNow);
            this.FailOn(() => DrugStack == null || DrugStack.Destroyed || DrugStack.stackCount < 1);

            yield return Toils_Goto.GotoThing(TargetIndex.A, PathEndMode.Touch);

            Toil buy = ToilMaker.MakeToil("NarcoticsBuyDrug");
            buy.initAction = () =>
            {
                Pawn dealer = Dealer;
                Thing stack = DrugStack;
                if (dealer == null || stack == null || stack.Destroyed || stack.stackCount < 1)
                {
                    return;
                }

                ThingDef drugDef = stack.def;
                int price = Mathf.Max(1, Mathf.RoundToInt(drugDef.BaseMarketValue));
                if (!TryPaySilver(pawn.Map, dealer, price))
                {
                    return;
                }

                Thing bought = stack.SplitOff(1);
                if (bought == null)
                {
                    return;
                }

                if (!pawn.inventory.innerContainer.TryAdd(bought))
                {
                    GenPlace.TryPlaceThing(bought, pawn.Position, pawn.Map, ThingPlaceMode.Near);
                }

                // Follow-up ingest from inventory on next AI tick via chemical need,
                // but try immediately if possible.
                Thing inInv = null;
                List<Thing> inv = pawn.inventory.innerContainer.InnerListForReading;
                for (int i = 0; i < inv.Count; i++)
                {
                    if (inv[i].def == drugDef)
                    {
                        inInv = inv[i];
                        break;
                    }
                }

                if (inInv != null && !pawn.Downed)
                {
                    Job ingest = JobMaker.MakeJob(JobDefOf.Ingest, inInv);
                    ingest.count = 1;
                    pawn.jobs.TryTakeOrderedJob(ingest, JobTag.SatisfyingNeeds);
                }
            };
            buy.defaultCompleteMode = ToilCompleteMode.Instant;
            yield return buy;
        }

        private static bool TryPaySilver(Map map, Pawn dealer, int price)
        {
            int remaining = price;
            List<Thing> silver = map.listerThings.ThingsOfDef(ThingDefOf.Silver);
            // Copy list because we mutate stacks.
            List<Thing> copy = new List<Thing>(silver);
            for (int i = 0; i < copy.Count && remaining > 0; i++)
            {
                Thing s = copy[i];
                if (s.Destroyed || s.IsForbidden(Faction.OfPlayer))
                {
                    continue;
                }

                int take = Mathf.Min(remaining, s.stackCount);
                Thing paid = s.SplitOff(take);
                remaining -= take;
                if (!dealer.inventory.innerContainer.TryAdd(paid))
                {
                    paid.Destroy();
                }
            }

            return remaining <= 0;
        }
    }
}
