import { PrismaClient } from "@prisma/client";
import { KINK_CATALOG } from "../src/data/kinks";

const prisma = new PrismaClient();

async function main() {
  for (const [index, kink] of KINK_CATALOG.entries()) {
    await prisma.kink.upsert({
      where: { key: kink.key },
      create: { ...kink, order: index },
      update: {
        name: kink.name,
        description: kink.description,
        hasRoleVariant: kink.hasRoleVariant,
        roleA: kink.roleA ?? null,
        roleB: kink.roleB ?? null,
        intensity: kink.intensity,
        order: index,
      },
    });
  }
  // eslint-disable-next-line no-console
  console.log(`Seeded ${KINK_CATALOG.length} kinks.`);
}

main()
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
