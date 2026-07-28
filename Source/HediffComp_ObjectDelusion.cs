using System.Collections.Generic;
using RimWorld;
using Verse;

namespace Narcotics
{
    public class HediffCompProperties_ObjectDelusion : HediffCompProperties
    {
        public List<string> objectDefNames;

        public HediffCompProperties_ObjectDelusion()
        {
            compClass = typeof(HediffComp_ObjectDelusion);
        }
    }

    public class HediffComp_ObjectDelusion : HediffComp
    {
        public string objectLabel;
        private bool announced;

        private static readonly string[] FallbackObjectDefs =
        {
            "DiningChair", "Stool", "Table1x2c", "Bed", "Battery",
            "Gun_AssaultRifle", "MealSimple", "Steel", "WoodLog", "Apparel_Pants"
        };

        public override void CompPostPostAdd(DamageInfo? dinfo)
        {
            base.CompPostPostAdd(dinfo);
            EnsureObjectChosen();
        }

        public override void CompPostMerged(Hediff other)
        {
            base.CompPostMerged(other);
            // Keep existing delusion for this trip.
            EnsureObjectChosen();
        }

        public override void CompExposeData()
        {
            base.CompExposeData();
            Scribe_Values.Look(ref objectLabel, "objectLabel");
            Scribe_Values.Look(ref announced, "announced", false);
        }

        public override string CompLabelInBracketsExtra
        {
            get
            {
                if (objectLabel.NullOrEmpty())
                {
                    return null;
                }

                return "believes they are " + objectLabel;
            }
        }

        private void EnsureObjectChosen()
        {
            if (!objectLabel.NullOrEmpty())
            {
                return;
            }

            objectLabel = PickRandomObjectLabel();
            if (!announced && Pawn != null && Pawn.Spawned && Pawn.IsColonistPlayerControlled)
            {
                announced = true;
                Messages.Message(
                    "Narcotics_SalviaDelusion".Translate(Pawn.LabelShort, objectLabel),
                    Pawn,
                    MessageTypeDefOf.NeutralEvent);
            }
        }

        private string PickRandomObjectLabel()
        {
            List<string> names = ((HediffCompProperties_ObjectDelusion)props).objectDefNames;
            List<string> pool = (names != null && names.Count > 0)
                ? names
                : new List<string>(FallbackObjectDefs);

            for (int attempt = 0; attempt < 8; attempt++)
            {
                string defName = pool.RandomElement();
                ThingDef def = DefDatabase<ThingDef>.GetNamedSilentFail(defName);
                if (def != null && !def.label.NullOrEmpty())
                {
                    return def.label;
                }
            }

            return "stool";
        }
    }
}
