-- RenameEnumValue: keep existing Response rows pointing at the same role, just under
-- the new generic names, instead of dropping/recreating the type (which Postgres would
-- otherwise require and would need every existing GIVE/RECEIVE row remapped by hand).
ALTER TYPE "ResponseRole" RENAME VALUE 'GIVE' TO 'ROLE_A';
ALTER TYPE "ResponseRole" RENAME VALUE 'RECEIVE' TO 'ROLE_B';

-- AlterTable
ALTER TABLE "Kink" ADD COLUMN     "roleA" TEXT,
ADD COLUMN     "roleB" TEXT;
