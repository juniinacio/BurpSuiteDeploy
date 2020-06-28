class SiteTreeCache {
    static [object] $SiteTree

    static [object] Get([string]$parentId, [string]$name, [string]$type) {
        if ($type -eq 'Folders') {
            return @([SiteTreeCache]::SiteTree.Folders | Where-Object { ($_.name -eq $name) -and ($_.parent_id -eq $parentId) })[0]
        }
        return @([SiteTreeCache]::SiteTree.Sites | Where-Object { ($_.name -eq $name) -and ($_.parent_id -eq $parentId) })[0]
    }
}
