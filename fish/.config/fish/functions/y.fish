function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi --cwd-file="$tmp" $argv

    if set cwd (cat "$tmp")
        and test -n "$cwd"
        and test "$cwd" != "$PWD"
        cd "$cwd"
    end

    rm -f "$tmp"
end
