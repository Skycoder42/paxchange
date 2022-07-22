import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import 'aur_options.dart';

Future<void> main(List<String> arguments) async {
  final aurDir = Directory(arguments.first);
  if (!aurDir.existsSync()) {
    throw Exception('$aurDir must exist');
  }

  final options = await _readPubspecWithAur();
  if (options.pubspec.version?.isPreRelease ?? true) {
    throw Exception('version must not be empty and cannot be a pre-release!');
  }

  final changelog = File('CHANGELOG.md');
  if (!changelog.existsSync()) {
    throw Exception('$changelog must exist');
  }

  final pkgbuild = File.fromUri(aurDir.uri.resolve('PKGBUILD'));
  await pkgbuild.writeAsString(_pkgbuildTemplate(options));

  await changelog.copy(aurDir.uri.resolve('CHANGELOG.md').toFilePath());
}

Future<PubspecWithAur> _readPubspecWithAur() async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw Exception('$pubspecFile must exist');
  }

  final pubspecYaml = await pubspecFile.readAsString();

  final pubspec = Pubspec.parse(
    pubspecYaml,
    sourceUrl: pubspecFile.uri,
  );

  final aurOptionsPubspecView = checkedYamlDecode(
    pubspecYaml,
    AurOptionsPubspecView.fromYaml,
    sourceUrl: pubspecFile.uri,
  );

  return PubspecWithAur(
    pubspec: pubspec,
    aurOptions: aurOptionsPubspecView.aur,
    executables: aurOptionsPubspecView.executables,
  );
}

String _pkgbuildTemplate(PubspecWithAur options) => '''
# Maintainer: ${options.aurOptions.maintainer}
pkgname='${options.pubspec.name}'
pkgver='${options.pubspec.version!.toString().replaceAll('-', '_')}'
pkgrel='${options.aurOptions.pkgrel}'
pkgdesc='${options.pubspec.description ?? ''}'
arch=('x86_64' 'i686' 'armv7h' 'aarch64')
url='${options.pubspec.homepage ?? options.pubspec.repository ?? ''}'
license=('${options.aurOptions.license}')
depends=(${options.aurOptions.depends.map((d) => "'$d'").join(' ')})
makedepends=(${_getDartDependency(options.pubspec).join(' ')} 'go-yq')
_pkgdir="\$pkgname-\${pkgver//_/-}"
source=("\$_pkgdir.tar.gz::${_getSourceUrl(options.pubspec)}")
changelog='CHANGELOG.md'
b2sums=('NEEDS_UPDATE')

prepare() {
  cd "\$_pkgdir"
  yq e -i "del(.dependency_overrides)" pubspec.yaml
  dart pub get
}

build() {
  cd "\$_pkgdir"
  ${_getBuildSteps(options).join('\n  ')}
}

check() {
  cd "\$_pkgdir"
  dart analyze --no-fatal-warnings
  # dart test
}

package() {
  cd "\$_pkgdir"
  ${_getInstallSteps(options).join('\n  ')}
  install -D -m644 "LICENSE" "\$pkgdir/usr/share/licenses/\$pkgname/LICENSE"
}
''';

Iterable<String> _getDartDependency(Pubspec pubspec) sync* {
  final dartSdkConstraints = pubspec.environment?['sdk'];
  if (dartSdkConstraints is VersionRange) {
    final minVersion = dartSdkConstraints.min;
    if (minVersion != null) {
      final strippedMin =
          minVersion.isPreRelease ? minVersion.nextPatch : minVersion;
      yield dartSdkConstraints.includeMin
          ? "'dart>=$strippedMin'"
          : "'dart>$strippedMin'";
    }
    final maxVersion = dartSdkConstraints.max;
    if (maxVersion != null) {
      final strippedMax =
          maxVersion.isPreRelease ? maxVersion.nextPatch : maxVersion;
      yield dartSdkConstraints.includeMax
          ? "'dart<=$strippedMax'"
          : "'dart<$strippedMax'";
    }

    if (minVersion != null || maxVersion != null) {
      return;
    }
  }

  yield "'dart'";
}

Uri _getSourceUrl(Pubspec pubspec) {
  final baseRepo = pubspec.repository?.toString() ?? pubspec.homepage;
  if (baseRepo == null) {
    throw Exception('Either repository or homepage must be set!');
  }

  return Uri.parse(baseRepo.endsWith('/') ? baseRepo : '$baseRepo/')
      .resolve('archive/refs/tags/v${pubspec.version}.tar.gz');
}

Iterable<String> _getBuildSteps(PubspecWithAur options) sync* {
  if (options.executables.isEmpty) {
    throw Exception('Must define at least one executable!');
  }

  if (options.pubspec.devDependencies.containsKey('build_runner')) {
    yield 'dart run build_runner build --delete-conflicting-outputs --release';
  }

  yield* options.executables.entries.map(
    (entry) => 'dart compile exe '
        "-o 'bin/${entry.key}' "
        "-S 'bin/${entry.key}.symbols' "
        "'bin/${entry.value ?? entry.key}.dart'",
  );
}

Iterable<String> _getInstallSteps(PubspecWithAur options) sync* {
  if (options.executables.isEmpty) {
    throw Exception('Must define at least one executable!');
  }

  yield* options.executables.entries.map(
    (entry) => 'install -D -m755 '
        "'bin/${entry.key}' "
        "\"\$pkgdir\"'/usr/bin/${entry.key}'",
  );
}
