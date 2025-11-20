import 'package:arrow_openapi/arrow_openapi.dart';

// This annotation will trigger code generation
// Run: dart run build_runner build
@GenerateArrowRouter(
  'example/petstore.yaml',
  generateHandlers: true,
  generateModels: true,
  generateJsonSerializable: true,
)
class PetStoreApi {}

// After running build_runner, a file 'example.openapi.dart' will be generated
// with:
// - Pet and Pets model classes with fromJson/toJson
// - Handler typedefs for each operation
// - $PetStoreApi.createRouter() factory method
// - Handler stub functions

// Example usage after generation:
/*
import 'example.openapi.dart';

void main() async {
  // Implement your handlers
  Future<Response> handleListPets(Request req) async {
    final limit = req.uri.queryParameters['limit'];

    // Your business logic here
    final pets = await fetchPetsFromDatabase(limit: limit);

    return req.respond.ok(data: pets.toJson());
  }

  Future<Response> handleGetPetById(Request req) async {
    final petId = req.params.get('petId');

    final pet = await findPetById(petId);
    if (pet == null) {
      return req.respond.notFound(msg: 'Pet not found');
    }

    return req.respond.ok(data: pet.toJson());
  }

  // Create the router with your handlers
  final router = $PetStoreApi.createRouter(
    listPets: handleListPets,
    getPetById: handleGetPetById,
    createPet: handleCreatePet,
    updatePetById: handleUpdatePetById,
    deletePetById: handleDeletePetById,
  );

  // Run the Arrow server
  final app = Arrow();
  await app.run(() => router, port: 8080);
}
*/
