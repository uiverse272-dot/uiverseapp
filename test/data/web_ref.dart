import 'dart:convert';
import 'dart:io';

/// Reference output captured from the web TS (`src/lib/*.ts`) by running it
/// under Node. Regenerate with `fixtures/gen_web_reference.mts` (see its header).
final Map<String, Object?> webRef = jsonDecode(
  File('test/data/fixtures/web_reference.json').readAsStringSync(),
) as Map<String, Object?>;

List<Object?> refList(String key) => webRef[key]! as List<Object?>;

Map<String, Object?> obj(Object? o) => o! as Map<String, Object?>;

List<Object?> list(Object? o) => o! as List<Object?>;

List<String> strings(Object? o) => list(o).cast<String>();
