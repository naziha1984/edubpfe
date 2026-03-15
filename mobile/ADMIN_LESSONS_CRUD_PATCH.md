# Admin CRUD Lessons - PR5

## 📦 Fichiers Créés/Modifiés

### Frontend (Flutter)

1. **`lib/models/lesson_model.dart`** - Modèle Lesson
   - Propriétés: id, subjectId, title, description, content, order, isActive, createdAt, updatedAt
   - Méthodes: fromJson, toJson, toJsonForUpdate, copyWith

2. **`lib/services/lessons_service.dart`** - Service API pour CRUD lessons
   - `getLessonsBySubject()` - GET /subjects/:id/lessons
   - `getLessonById()` - GET /lessons/:id
   - `createLesson()` - POST /lessons
   - `updateLesson()` - PUT /lessons/:id
   - `deleteLesson()` - DELETE /lessons/:id

3. **`lib/providers/lessons_provider.dart`** - Provider pour gérer le CRUD
   - `loadLessonsBySubject()` - Charge les lessons d'un subject
   - `createLesson()` - Crée une nouvelle lesson
   - `updateLesson()` - Met à jour une lesson
   - `deleteLesson()` - Supprime une lesson
   - États: loading, error, currentSubjectId

4. **`lib/pages/admin_lessons_screen.dart`** - Écran de gestion des lessons
   - Liste des lessons par subject avec animations Fade
   - Hero animation pour le titre du subject
   - Bouton FAB pour créer
   - Actions edit/delete sur chaque card
   - États: loading, empty, error
   - RefreshIndicator pour recharger

5. **`lib/components/lesson_card.dart`** - Card de lesson avec animations
   - Hero animation pour le titre
   - Fade + Scale animation d'apparition staggered
   - Affichage: order badge, title, description, content preview, status badge
   - Actions: Edit, Delete

6. **`lib/components/lesson_form_bottom_sheet.dart`** - BottomSheet moderne avec editor et preview
   - Tabs: Editor / Preview
   - Formulaire avec validation
   - Champs: subjectId (dropdown), title (required), order, description, content (textarea), isActive (switch)
   - Preview en temps réel
   - Hero animation pour le titre

7. **`lib/main.dart`** - Ajout de LessonsProvider
8. **`lib/pages/admin_subjects_screen.dart`** - Ajout de navigation vers AdminLessonsScreen

## 🎨 UI Features

### AdminLessonsScreen
- ✅ Hero animation pour le titre du subject
- ✅ Liste des lessons avec animations Fade staggered
- ✅ FloatingActionButton pour créer
- ✅ Actions Edit/Delete sur chaque card
- ✅ RefreshIndicator pour recharger
- ✅ États: loading skeleton, empty state, error state

### LessonCard
- ✅ Hero animation pour le titre (transition vers le form)
- ✅ Fade + Scale animation d'apparition staggered (index-based delay)
- ✅ Affichage: order badge, title, description, content preview, status badge
- ✅ Actions Edit/Delete visibles

### LessonFormBottomSheet
- ✅ BottomSheet moderne avec handle bar
- ✅ Tabs: Editor / Preview (toggle)
- ✅ Formulaire avec validation complète
- ✅ Champs: subjectId (dropdown), title (required), order (number), description, content (textarea 8 lignes), isActive (switch)
- ✅ Preview en temps réel de tous les champs
- ✅ Hero animation pour le titre (transition depuis la card)

## 🔌 API Endpoints Utilisés

### GET /api/subjects/:id/lessons
**Public endpoint** - Récupère toutes les lessons d'un subject
**Response:**
```json
[
  {
    "id": "...",
    "subjectId": "...",
    "title": "Introduction to Algebra",
    "description": "...",
    "content": "...",
    "order": 1,
    "isActive": true,
    "createdAt": "...",
    "updatedAt": "..."
  }
]
```

### GET /api/lessons/:id
**Admin only** - Récupère une lesson par ID
**Response:**
```json
{
  "id": "...",
  "subjectId": "...",
  "title": "...",
  "description": "...",
  "content": "...",
  "order": 1,
  "isActive": true,
  "createdAt": "...",
  "updatedAt": "..."
}
```

### POST /api/lessons
**Admin only** - Crée une nouvelle lesson
**Body:**
```json
{
  "subjectId": "...",
  "title": "Introduction to Algebra",
  "description": "Basic algebra concepts",
  "content": "Lesson content here...",
  "order": 1,
  "isActive": true
}
```
**Response:** Lesson créée

### PUT /api/lessons/:id
**Admin only** - Met à jour une lesson
**Body:**
```json
{
  "subjectId": "...",
  "title": "Updated Title",
  "description": "Updated description",
  "content": "Updated content",
  "order": 2,
  "isActive": false
}
```
**Response:** Lesson mise à jour

### DELETE /api/lessons/:id
**Admin only** - Supprime une lesson
**Response:** 204 No Content

## 🧪 Comment Tester

### Prérequis
1. Backend démarré : `npm run start:dev` (port 3000)
2. Flutter app démarrée : `flutter run -d chrome`
3. Se connecter avec un compte ADMIN
4. Avoir au moins un subject créé

### Test 1 : Liste des Lessons

1. **Se connecter en tant qu'ADMIN**
   - Email : `admin@edubridge.com`
   - Password : `admin123`

2. **Naviguer vers Manage Subjects**
   - Depuis AdminHomeScreen, cliquer sur "Manage Subjects"

3. **Cliquer sur un Subject** (ou sur Edit puis naviguer)
   - ✅ Doit naviguer vers AdminLessonsScreen avec Hero animation
   - ✅ Titre du subject avec Hero tag

4. **Vérifier la liste** :
   - ✅ Doit afficher toutes les lessons du subject
   - ✅ Chaque lesson dans une card avec animations Fade staggered
   - ✅ Hero animation sur le titre de chaque lesson
   - ✅ Order badge visible si order défini
   - ✅ Status badge (Active/Inactive) visible
   - ✅ Content preview visible si content existe

### Test 2 : Créer une Lesson

1. **Cliquer sur le FAB "Create Lesson"** ou le bouton "+" dans l'app bar

2. **Vérifier le BottomSheet** :
   - ✅ BottomSheet s'ouvre avec animation slide up
   - ✅ Hero animation sur le titre (depuis "Create Lesson")
   - ✅ Tabs Editor/Preview visibles
   - ✅ Tab Editor sélectionné par défaut

3. **Remplir le formulaire (Editor tab)** :
   - Subject: Sélectionner dans le dropdown (pré-sélectionné si depuis subject)
   - Title: "Test Lesson" (required)
   - Order: "1" (optionnel, number)
   - Description: "This is a test lesson" (optionnel)
   - Content: "Lesson content here..." (optionnel, textarea 8 lignes)
   - Status: Active (switch)

4. **Tester le Preview tab** :
   - ✅ Cliquer sur "Preview"
   - ✅ Doit afficher tous les champs remplis en preview
   - ✅ Subject name affiché
   - ✅ Title, description, content affichés
   - ✅ Order et status affichés

5. **Valider** :
   - ✅ Retourner sur Editor tab ou rester sur Preview
   - ✅ Cliquer sur "Create"
   - ✅ BottomSheet se ferme
   - ✅ Toast success affiché: "Lesson created successfully!"
   - ✅ Nouvelle lesson apparaît dans la liste avec animation Fade

6. **Tester la validation** :
   - ✅ Laisser title vide → doit afficher "Title is required"
   - ✅ Laisser subject non sélectionné → doit afficher "Please select a subject"
   - ✅ Order invalide (texte) → doit afficher "Please enter a valid number"

### Test 3 : Éditer une Lesson

1. **Cliquer sur "Edit" sur une card de lesson**

2. **Vérifier le BottomSheet** :
   - ✅ BottomSheet s'ouvre avec les champs pré-remplis
   - ✅ Hero animation sur le titre (transition depuis la card)
   - ✅ Titre: "Edit Lesson"

3. **Modifier les champs** :
   - Changer le title
   - Modifier la description
   - Modifier le content
   - Changer l'order
   - Changer le status (Active/Inactive)

4. **Tester le Preview** :
   - ✅ Cliquer sur Preview
   - ✅ Vérifier que les modifications sont visibles

5. **Valider** :
   - ✅ Cliquer sur "Update"
   - ✅ BottomSheet se ferme
   - ✅ Toast success affiché: "Lesson updated successfully!"
   - ✅ Lesson mise à jour dans la liste

### Test 4 : Supprimer une Lesson

1. **Cliquer sur "Delete" sur une card de lesson**

2. **Vérifier la confirmation** :
   - ✅ Dialog de confirmation s'affiche
   - ✅ Message: "Are you sure you want to delete..."

3. **Confirmer** :
   - ✅ Cliquer sur "Delete" dans le dialog
   - ✅ Dialog se ferme
   - ✅ Toast success affiché: "Lesson deleted successfully!"
   - ✅ Lesson disparaît de la liste

### Test 5 : Animations

1. **Hero Animation** :
   - ✅ Titre du subject dans AdminLessonsScreen → Hero tag
   - ✅ Titre de chaque lesson dans LessonCard → Hero tag
   - ✅ Transition fluide lors de l'ouverture du form
   - ✅ Transition fluide lors de la fermeture du form

2. **Fade List Animation** :
   - ✅ Chaque lesson apparaît avec Fade + Scale
   - ✅ Delay basé sur l'index (staggered)
   - ✅ Animation fluide et performante

3. **Navigation Animation** :
   - ✅ Transition fade/slide lors de la navigation depuis AdminSubjectsScreen
   - ✅ Hero animation sur le titre du subject

## 🔍 Points de Vérification

### CRUD Operations
- [x] Create lesson fonctionne
- [x] Read lessons (liste par subject) fonctionne
- [x] Update lesson fonctionne
- [x] Delete lesson fonctionne
- [x] Validation des champs fonctionne
- [x] Gestion des erreurs fonctionne

### UI/UX
- [x] BottomSheet moderne avec tabs Editor/Preview
- [x] Hero animations sur les titres
- [x] Fade list animations staggered
- [x] Cards avec animations fluides
- [x] Toast notifications pour success/error
- [x] Dialog de confirmation pour delete
- [x] États loading/empty/error gérés
- [x] RefreshIndicator fonctionnel

### Editor & Preview
- [x] Editor avec tous les champs
- [x] Preview en temps réel
- [x] Toggle entre Editor et Preview
- [x] Textarea pour content (8 lignes)
- [x] Dropdown pour subject selection

### Validation
- [x] Title required
- [x] SubjectId required
- [x] Order optionnel (number validation)
- [x] Description optionnel
- [x] Content optionnel
- [x] isActive avec switch moderne

## 🐛 Dépannage

### Problème : Les Hero animations ne fonctionnent pas
**Solution** :
1. Vérifier que les Hero tags sont uniques et cohérents
2. Vérifier que Material widget est utilisé dans Hero
3. Vérifier que les tags correspondent entre card et form

### Problème : Le Preview ne se met pas à jour
**Solution** :
1. Vérifier que setState est appelé lors du changement de tab
2. Vérifier que les controllers sont bien liés aux TextFields
3. Vérifier que le Preview lit bien les valeurs des controllers

### Problème : La liste ne se charge pas
**Solution** :
1. Vérifier que le subjectId est bien passé
2. Vérifier que loadLessonsBySubject est bien appelé
3. Vérifier les logs : `❌ [LessonsProvider] Error loading lessons`
4. Vérifier que le backend répond correctement

## 📝 Notes

- Les champs `level` et `language` demandés ne sont pas dans le backend actuel
- Si besoin, ajouter ces champs au backend et mettre à jour le modèle
- Le BottomSheet utilise `isScrollControlled: true` pour permettre le scroll
- Les animations Hero sont fluides et performantes
- Les animations Fade sont staggered pour un effet visuel agréable
- Le code est prêt pour l'ajout de fonctionnalités futures (bulk operations, export, etc.)

## ✅ Checklist de Validation

- [x] LessonModel créé
- [x] LessonsService créé avec tous les endpoints
- [x] LessonsProvider créé avec CRUD complet
- [x] AdminLessonsScreen créé avec liste et Hero animation
- [x] LessonCard créé avec animations Hero et Fade
- [x] LessonFormBottomSheet créé avec Editor et Preview
- [x] Hero animations sur les titres
- [x] Fade list animations staggered
- [x] Toast notifications pour success/error
- [x] Dialog de confirmation pour delete
- [x] États loading/empty/error gérés
- [x] RefreshIndicator fonctionnel
- [x] Validation des champs fonctionnelle
- [x] Editor et Preview fonctionnels
- [x] Navigation depuis AdminSubjectsScreen fonctionnelle
