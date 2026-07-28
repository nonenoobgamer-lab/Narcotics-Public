using RimWorld;
using Verse;

namespace Narcotics
{
    public class IncidentWorker_DrugDealerArrival : IncidentWorker_TraderCaravanArrival
    {
        protected override bool TryExecuteWorker(IncidentParms parms)
        {
            TraderKindDef dealer = DefDatabase<TraderKindDef>.GetNamedSilentFail("Narcotics_DrugDealer");
            if (dealer == null)
            {
                return false;
            }

            parms.traderKind = dealer;
            return base.TryExecuteWorker(parms);
        }
    }
}
