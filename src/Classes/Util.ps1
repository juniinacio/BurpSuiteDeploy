class Util {
    static [object] GetResourceId([string]$name, [string]$type) {
        $resourceId = @($type.TrimEnd("/"), $name.TrimStart("/")) -join "/"
        return $resourceId
    }

    static [object] GetResourceId([string]$name, [string]$type, [string]$parentType) {
        $resourceId = @($parentType.TrimEnd("/"), (($name.TrimStart("/")) -split "/")[0], $type.TrimEnd("/"), (($name.TrimStart("/")) -split "/")[-1]) -join "/"
        return $resourceId
    }

    static [object] GetResourceType([string]$type) {
        $resourceType = $type.TrimEnd("/")
        return $resourceType
    }

    static [object] GetResourceType([string]$type, [string]$parentType) {
        $resourceType = @($parentType.TrimEnd("/"), $type.TrimStart("/")) -join "/"
        return $resourceType
    }

    static [object] GetResourceName([string]$name) {
        $resourceName = (($name.TrimStart("/")) -split "/")[-1]
        return $resourceName
    }
}
