set windows-shell := [ "nu", "-c" ]

_default:
 @just --list

clean:
  crystal clear_cache

[windows]
check *flags:
  ./bin/ameba.exe {{ flags }}

[unix]
check *flags:
  ./bin/ameba {{ flags }}

docs *flags:
  crystal docs {{ flags }}

test *spec_files_or_flags:
  crystal spec --progress {{ spec_files_or_flags }}

build *flags:
  shards build --production --release --no-debug --verbose --progress --time {{ flags }}

run *flags:
  shards run --error-trace --progress {{ flags }}

exec exec_file *flags:
  crystal run --error-trace --progress {{ flags }} {{ exec_file }}

bench bench_file *flags:
  crystal run --release --progress {{ flags }} {{ bench_file }}
