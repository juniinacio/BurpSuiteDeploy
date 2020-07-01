# Idea from http://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell
# borrowed from http://stackoverflow.com/questions/8982782/does-anyone-have-a-dependency-graph-and-topological-sorting-code-snippet-for-pow
function _cloneObject {
    [cmdletbinding()]
    param(
        [object] $InputObject
    )

    $memoryStream = new-object IO.MemoryStream

    $binaryFormatter = new-object Runtime.Serialization.Formatters.Binary.BinaryFormatter
    $binaryFormatter.Serialize($memoryStream, $InputObject)

    $memoryStream.Position = 0

    $binaryFormatter.Deserialize($memoryStream)
}

function _convertToHashtable {
    [OutputType([System.Collections.Hashtable])]
    [cmdletbinding()]
    param(
        [object]$InputObject
    )

    $ht = @{}

    $InputObject | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $ht.$_ = $InputObject.$_
    }

    $ht
}

function _createTempFile {
    [cmdletbinding()]
    param(
        [object] $InputObject
    )

    $tempFile = New-TemporaryFile
    if (-not ([string]::IsNullOrEmpty($InputObject))) {
        Out-File -NoNewline -InputObject $InputObject -FilePath $tempFile
    }
    $tempFile
}

function _sortDeployment {
    [OutputType([System.Object[]])]
    [cmdletbinding()]
    param(
        [object[]] $Resources
    )

    $order = @{}

    foreach ($resource in $Resources) {
        if ($resource.dependsOn) {
            if(-not $order.ContainsKey($resource.ResourceId)) {
                $order.add($resource.ResourceId, $resource.dependsOn)
            }
        }
    }

    if($order.Keys.Count -gt 0) {
        $deployOrder = _sortTopologically $order
        _sortWithCustomList -InputObject $Resources -Property ResourceId -CustomList $deployOrder
    } else {
        $Resources
    }
}

# Thanks to http://stackoverflow.com/questions/8982782/does-anyone-have-a-dependency-graph-and-topological-sorting-code-snippet-for-pow
# Input is a hashtable of @{ID = @(Depended,On,IDs);...}
function _sortTopologically {
    [OutputType([System.Collections.ArrayList])]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable] $EdgeList
    )

    # Make sure we can use HashSet
    Add-Type -AssemblyName System.Core

    # Clone it so as to not alter original
    $currentEdgeList = [hashtable] (_cloneObject $EdgeList)

    # algorithm from http://en.wikipedia.org/wiki/Topological_sorting#Algorithms
    $topologicallySortedElements = New-Object System.Collections.ArrayList
    $setOfAllNodesWithNoIncomingEdges = New-Object System.Collections.Queue

    $fasterEdgeList = @{}

    # Keep track of all nodes in case they put it in as an edge destination but not source
    $allTheNodes = New-Object -TypeName System.Collections.Generic.HashSet[object] -ArgumentList (, [object[]] $currentEdgeList.Keys)

    foreach ($currentNode in $currentEdgeList.Keys) {
        $currentDestinationNodes = [array] $currentEdgeList[$currentNode]
        if ($currentDestinationNodes.Length -eq 0) {
            $setOfAllNodesWithNoIncomingEdges.Enqueue($currentNode)
        }

        foreach ($currentDestinationNode in $currentDestinationNodes) {
            if (!$allTheNodes.Contains($currentDestinationNode)) {
                [void] $allTheNodes.Add($currentDestinationNode)
            }
        }

        # Take this time to convert them to a HashSet for faster operation
        $currentDestinationNodes = New-Object -TypeName System.Collections.Generic.HashSet[object] -ArgumentList (, [object[]] $currentDestinationNodes )
        [void] $fasterEdgeList.Add($currentNode, $currentDestinationNodes)
    }

    # Now let's reconcile by adding empty dependencies for source nodes they didn't tell us about
    foreach ($currentNode in $allTheNodes) {
        if (!$currentEdgeList.ContainsKey($currentNode)) {
            [void] $currentEdgeList.Add($currentNode, (New-Object -TypeName System.Collections.Generic.HashSet[object]))
            $setOfAllNodesWithNoIncomingEdges.Enqueue($currentNode)
        }
    }

    $currentEdgeList = $fasterEdgeList

    while ($setOfAllNodesWithNoIncomingEdges.Count -gt 0) {
        $currentNode = $setOfAllNodesWithNoIncomingEdges.Dequeue()
        [void] $currentEdgeList.Remove($currentNode)
        [void] $topologicallySortedElements.Add($currentNode)

        foreach ($currentEdgeSourceNode in $currentEdgeList.Keys) {
            $currentNodeDestinations = $currentEdgeList[$currentEdgeSourceNode]
            if ($currentNodeDestinations.Contains($currentNode)) {
                [void] $currentNodeDestinations.Remove($currentNode)

                if ($currentNodeDestinations.Count -eq 0) {
                    [void] $setOfAllNodesWithNoIncomingEdges.Enqueue($currentEdgeSourceNode)
                }
            }
        }
    }

    if ($currentEdgeList.Count -gt 0) {
        throw "Graph has at least one cycle!"
    }

    return $topologicallySortedElements
}

# Thanks to http://stackoverflow.com/questions/8982782/does-anyone-have-a-dependency-graph-and-topological-sorting-code-snippet-for-pow
# Input is a hashtable of @{ID = @(Depended,On,IDs);...}
function _sortWithCustomList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
    Param (
        [parameter(ValueFromPipeline=$true)]
        [PSObject]
        $InputObject,

        [parameter(Position=1)]
        [String]
        $Property,

        [parameter()]
        [Object[]]
        $CustomList
    )

    begin {
        # convert customList (array) to hash
        $hash = @{}
        $rank = 0
        $customList | Select-Object -Unique | ForEach-Object {
            $key = $_
            $hash.Add($key, $rank)
            $rank++
        }

        # create script block for sorting
        # items not in custom list will be last in sort order
        $sortOrder = {
            $key = if ($Property) { $_.$Property } else { $_ }
            $rank = $hash[$key]
            if ($null -ne $rank) {
                $rank
            } else {
                [System.Double]::PositiveInfinity
            }
        }

        # create a place to collect objects from pipeline
        # (I don't know how to match behavior of Sort's InputObject parameter)
        $objects = @()
    }

    process {
        $objects += $InputObject
    }

    end {
        $objects | Sort-Object -Property $sortOrder
    }
}

function _tryGetProperty {
    param(
        [object] $InputObject,
        [string] $PropertyName
    )

    if ((@($InputObject.PSObject.Properties.Match($PropertyName)).Count -gt 0) -and ($null -ne $InputObject.$PropertyName)) {
        return $InputObject.$PropertyName
    }

    return $null
}
