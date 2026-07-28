using System.Collections.Generic;
using RimWorld;
using Verse;

namespace Narcotics
{
    public static class NarcoticsDrugUtility
    {
        private static readonly string[] DrugDefNames =
        {
            "Percocet",
            "Xanax",
            "Weed",
            "Cocaine",
            "Fentanyl",
            "Meth",
            "PsychedelicMushrooms",
            "Salvia"
        };

        public static IEnumerable<ThingDef> AllNarcoticsDrugs()
        {
            for (int i = 0; i < DrugDefNames.Length; i++)
            {
                ThingDef def = DefDatabase<ThingDef>.GetNamedSilentFail(DrugDefNames[i]);
                if (def != null)
                {
                    yield return def;
                }
            }
        }

        public static ThingDef DrugForChemical(ChemicalDef chemical)
        {
            if (chemical == null)
            {
                return null;
            }

            foreach (ThingDef def in AllNarcoticsDrugs())
            {
                CompProperties_Drug props = def.GetCompProperties<CompProperties_Drug>();
                if (props != null && props.chemical == chemical)
                {
                    return def;
                }
            }

            return null;
        }

        public static bool IsNarcoticsChemical(ChemicalDef chemical)
        {
            return DrugForChemical(chemical) != null;
        }
    }
}
