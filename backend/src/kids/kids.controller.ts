import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { KidsService } from "./kids.service";
import { CreateKidDto } from "./dto/create-kid.dto";
import { UpdateKidDto } from "./dto/update-kid.dto";
import { SetPinDto } from "./dto/set-pin.dto";
import { VerifyPinDto } from "./dto/verify-pin.dto";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { GetUser } from "../auth/decorators/get-user.decorator";
import { UserRole } from "../users/schemas/user.schema";

@Controller("kids")
export class KidsController {
  constructor(
    private readonly kidsService: KidsService,
    private readonly jwtService: JwtService,
  ) {}

  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async findAll(@GetUser() user: any) {
    const kids = await this.kidsService.findAllByParentId(user.id);
    return kids.map((kid) => ({
      id: kid._id.toString(),
      firstName: kid.firstName,
      lastName: kid.lastName,
      dateOfBirth: kid.dateOfBirth,
      grade: kid.grade,
      schoolLevel: kid.schoolLevel,
      school: kid.school,
      isActive: kid.isActive,
      parentId: kid.parentId.toString(),
      createdAt: kid.createdAt,
      updatedAt: kid.updatedAt,
    }));
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createKidDto: CreateKidDto, @GetUser() user: any) {
    const kid = await this.kidsService.create(createKidDto, user.id);
    return {
      id: kid._id.toString(),
      firstName: kid.firstName,
      lastName: kid.lastName,
      dateOfBirth: kid.dateOfBirth,
      grade: kid.grade,
      schoolLevel: kid.schoolLevel,
      school: kid.school,
      isActive: kid.isActive,
      parentId: kid.parentId.toString(),
      createdAt: kid.createdAt,
      updatedAt: kid.updatedAt,
    };
  }

  @Put(":kidId")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async update(
    @Param("kidId") kidId: string,
    @Body() updateKidDto: UpdateKidDto,
    @GetUser() user: any,
  ) {
    const kid = await this.kidsService.update(kidId, updateKidDto, user.id);
    return {
      id: kid._id.toString(),
      firstName: kid.firstName,
      lastName: kid.lastName,
      dateOfBirth: kid.dateOfBirth,
      grade: kid.grade,
      schoolLevel: kid.schoolLevel,
      school: kid.school,
      isActive: kid.isActive,
      parentId: kid.parentId.toString(),
      createdAt: kid.createdAt,
      updatedAt: kid.updatedAt,
    };
  }

  @Delete(":kidId")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param("kidId") kidId: string, @GetUser() user: any) {
    await this.kidsService.remove(kidId, user.id);
  }

  @Put(":kidId/pin")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async setPin(
    @Param("kidId") kidId: string,
    @Body() setPinDto: SetPinDto,
    @GetUser() user: any,
  ) {
    await this.kidsService.setPin(kidId, setPinDto.pin, user.id);
    return { message: "PIN set successfully" };
  }

  @Post(":kidId/verify-pin")
  @HttpCode(HttpStatus.OK)
  async verifyPin(
    @Param("kidId") kidId: string,
    @Body() verifyPinDto: VerifyPinDto,
  ) {
    const isValid = await this.kidsService.verifyPin(kidId, verifyPinDto.pin);

    if (!isValid) {
      throw new UnauthorizedException("Invalid PIN");
    }

    // Generate kidToken (JWT with type KID_SESSION, 30 minutes)
    const payload = {
      sub: kidId,
      kidId: kidId,
      type: "KID_SESSION",
    };

    const kidToken = this.jwtService.sign(payload, { expiresIn: "30m" });

    return {
      kidToken,
      expiresIn: "30m",
    };
  }

  @Get("teachers/accepted")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async getAcceptedTeachers() {
    return this.kidsService.getAcceptedTeachers();
  }

  @Get("teachers/:teacherId/public")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async getTeacherPublicDetails(@Param("teacherId") teacherId: string) {
    return this.kidsService.getTeacherPublicDetails(teacherId);
  }

  @Put(":kidId/teacher/:teacherId")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.PARENT)
  async selectTeacherForKid(
    @Param("kidId") kidId: string,
    @Param("teacherId") teacherId: string,
    @GetUser() user: any,
  ) {
    return this.kidsService.selectTeacherForKid(kidId, teacherId, user.id);
  }
}
