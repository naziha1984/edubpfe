import { existsSync, mkdirSync } from "fs";
import { extname, join } from "path";
import { BadRequestException } from "@nestjs/common";
import { diskStorage } from "multer";

export const TEACHER_CV_UPLOAD_SUBDIR = "teacher-cvs";
export const TEACHER_CV_MAX_SIZE = 8 * 1024 * 1024; // 8MB
const allowedExtensions = new Set([".pdf", ".doc", ".docx"]);
const allowedMimeTypes = new Set([
  "application/pdf",
  "application/msword",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
]);

const uploadDir = join(process.cwd(), "uploads", TEACHER_CV_UPLOAD_SUBDIR);

export const teacherCvMulterOptions = {
  storage: diskStorage({
    destination: (_req, _file, cb) => {
      if (!existsSync(uploadDir)) {
        mkdirSync(uploadDir, { recursive: true });
      }
      cb(null, uploadDir);
    },
    filename: (_req, file, cb) => {
      const ext = extname(file.originalname).toLowerCase();
      const safe = `${Date.now()}-${Math.random().toString(36).slice(2, 11)}${ext}`;
      cb(null, safe);
    },
  }),
  limits: {
    fileSize: TEACHER_CV_MAX_SIZE,
  },
  fileFilter: (
    _req: unknown,
    file: Express.Multer.File,
    cb: (error: Error | null, acceptFile: boolean) => void,
  ) => {
    const ext = extname(file.originalname).toLowerCase();
    const isAllowedExt = allowedExtensions.has(ext);
    const isAllowedMime = allowedMimeTypes.has(
      (file.mimetype ?? "").toLowerCase(),
    );
    if (!isAllowedExt || !isAllowedMime) {
      cb(
        new BadRequestException(
          "Unsupported CV format. Allowed formats: PDF, DOC, DOCX",
        ) as unknown as Error,
        false,
      );
      return;
    }
    cb(null, true);
  },
};
