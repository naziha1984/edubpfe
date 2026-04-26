import { IsOptional, IsString, MaxLength } from "class-validator";

/**
 * DTO réservé aux évolutions futures (ex: note de soumission côté enseignant).
 * L'upload du fichier CV est transporté en multipart sous le champ `cv`.
 */
export class UpdateTeacherCvDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
