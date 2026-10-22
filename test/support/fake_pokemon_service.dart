import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:my_first_flutter_ui/models/pokemon.dart';
import 'package:my_first_flutter_ui/services/pokemon_service.dart';

const bulbasaur = Pokemon(
  name: 'bulbasaur',
  apiUrl: 'https://pokeapi.co/api/v2/pokemon/1/',
  types: ['grass', 'poison'],
);
const charmander = Pokemon(
  name: 'charmander',
  apiUrl: 'https://pokeapi.co/api/v2/pokemon/4/',
  types: ['fire'],
);
const samplePokemon = [bulbasaur, charmander];

class FakePokemonService extends PokemonService {
  FakePokemonService({required this.load})
    : super(client: MockClient((_) async => http.Response('{}', 200)));

  Future<List<Pokemon>> Function() load;
  int calls = 0;
  bool disposed = false;

  @override
  Future<List<Pokemon>> fetchPokemon() {
    calls++;
    return load();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
