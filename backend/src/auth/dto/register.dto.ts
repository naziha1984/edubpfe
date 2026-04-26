import {
  IsEmail,
  IsString,
  MinLength,
  IsNotEmpty,
  IsOptional,
  IsIn,
} from "class-validator";

export class RegisterDto {
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  password: string;

  @IsString()
  @IsNotEmpty()
  firstName: string;

  @IsString()
  @IsNotEmpty()
  lastName: string;

  /** Rôle à l'inscription : PARENT ou TEACHER (défaut: PARENT).
   *  Si TEACHER, le fichier CV multipart (`cv`) est obligatoire.
   */
  @IsOptional()
  @IsString()
  @IsIn(["PARENT", "TEACHER", "parent", "teacher"])
  role?: string;
}
