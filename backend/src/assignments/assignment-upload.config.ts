import { existsSync, mkdirSync } from "fs";
import { extname, join } from "path";
import { diskStorage } from "multer";

export const ASSIGNMENTS_UPLOAD_SUBDIR = "assignments";

const uploadDir = join(process.cwd(), "uploads", ASSIGNMENTS_UPLOAD_SUBDIR);

export const assignmentFilesMulterOptions = {
  storage: diskStorage({
    destination: (_req, _file, cb) => {
      if (!existsSync(uploadDir)) {
        mkdirSync(uploadDir, { recursive: true });
      }
      cb(null, uploadDir);
    },
    filename: (_req, file, cb) => {
      const safe = `${Date.now()}-${Math.random().toString(36).slice(2, 11)}${extname(file.originalname)}`;
      cb(null, safe);
    },
  }),
  limits: {
    fileSize: 80 * 1024 * 1024, // 80 Mo par fichier
  },
};
