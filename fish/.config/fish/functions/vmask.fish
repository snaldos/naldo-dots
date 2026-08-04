function vmask
    if test (count $argv) -eq 0
        echo "Usage: vmask <mask_file.tif>"
        return 1
    end
    magick $argv[1] -auto-level png:- | imv -
end
