use Pies;
use Panda::Common;
use File::Find;
use Shell::Command;

class Panda::Installer does Pies::Installer {
    sub die (Pies::Project $p, $d) is hidden_from_backtrace {
        X::Panda.new($p.name, 'install', $d).throw
    }

    has $.resources;
    has $.destdir;

    method sort-lib-contents(@lib) {
        my @pirs = @lib.grep({ $_ ~~  /\.pir$/});
        my @rest = @lib.grep({ $_ !~~ /\.pir$/});
        return @rest, @pirs;
    }

    method install(Pies::Project $p) {
        indir $!resources.workdir($p), {
            if 'blib'.IO ~~ :d {
                my @lib = find(dir => 'blib', type => 'file').list;
                for @.sort-lib-contents(@lib) -> $i {
                    # .substr(5) to skip 'blib/'
                    mkpath "$!destdir/{$i.dir.substr(5)}";
                    $i.IO.copy("$!destdir/{$i.Str.substr(5)}");
                }
            }
            if 'bin'.IO ~~ :d {
                for find(dir => 'bin', type => 'file').list -> $bin {
                    mkpath "$!destdir/{$bin.dir}";
                    $bin.IO.copy("$!destdir/$bin");
                    "$!destdir/$bin".IO.chmod(0o755) unless $*OS eq 'MSWin32';
                }
            }
            if 'doc'.IO ~~ :d {
                for find(dir => 'doc', type => 'file').list -> $doc {
                    my $path = "$!destdir/{$p.name.subst(':', '/', :g)}"
                             ~ "/{$doc.dir}";
                    mkpath $path;
                    $doc.IO.copy("$path/{$doc.name}");
                }
            }
            1;
        };
    }
}

# vim: ft=perl6
