-- AlterTable
ALTER TABLE "Kink" ADD COLUMN     "intensity" INTEGER NOT NULL DEFAULT 1;

-- CreateIndex
CREATE INDEX "Kink_intensity_idx" ON "Kink"("intensity");
