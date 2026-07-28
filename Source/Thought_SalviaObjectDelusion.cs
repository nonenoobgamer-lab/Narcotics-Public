using RimWorld;
using Verse;

namespace Narcotics
{
    public class ThoughtWorker_SalviaObjectDelusion : ThoughtWorker
    {
        protected override ThoughtState CurrentStateInternal(Pawn p)
        {
            Hediff hediff = p.health?.hediffSet?.GetFirstHediffOfDef(DefDatabase<HediffDef>.GetNamedSilentFail("SalviaHigh"));
            if (hediff == null)
            {
                return ThoughtState.Inactive;
            }

            HediffComp_ObjectDelusion comp = hediff.TryGetComp<HediffComp_ObjectDelusion>();
            if (comp == null || comp.objectLabel.NullOrEmpty())
            {
                return ThoughtState.Inactive;
            }

            return ThoughtState.ActiveAtStage(0);
        }
    }

    public class Thought_SalviaObjectDelusion : Thought_Situational
    {
        public override string LabelCap
        {
            get
            {
                Hediff hediff = pawn.health?.hediffSet?.GetFirstHediffOfDef(DefDatabase<HediffDef>.GetNamedSilentFail("SalviaHigh"));
                HediffComp_ObjectDelusion comp = hediff?.TryGetComp<HediffComp_ObjectDelusion>();
                if (comp != null && !comp.objectLabel.NullOrEmpty())
                {
                    return ("I am " + Find.ActiveLanguageWorker.WithIndefiniteArticle(comp.objectLabel)).CapitalizeFirst();
                }

                return base.LabelCap;
            }
        }
    }
}
