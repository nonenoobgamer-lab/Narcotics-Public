using Verse;

namespace Narcotics
{
    public class HediffCompProperties_DrugPrescription : HediffCompProperties
    {
        public ThingDef drugDef;

        public HediffCompProperties_DrugPrescription()
        {
            compClass = typeof(HediffComp_DrugPrescription);
        }
    }
}
