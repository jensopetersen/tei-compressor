xquery version "3.0";

let $doc := 
<doc xml:id="x">
    <a>
        <b x="1">text1<e>text2</e>text3</b>
        </a>
    <a u="5">
        <c>
            <d y="2" z="3">text4</d>
            </c>
    </a>
    <a>
        <c>
            <e y="4">text5<p n="6"/>text6</e>
            </c>
    </a>
</doc>

let $doc := doc('/db/test/test-doc.xml')

(:let $doc := doc('/db/apps/shakespeare/data/ham.xml'):)
return 
    let $paths :=
(:        we gather all nodes in the document:)
        let $nodes := ($doc//element(), $doc//attribute(), $doc//text())
        let $log := util:log("DEBUG", ("##$nodes): ", string-join($nodes, ' || ')))
        for $node in $nodes
(:        for each node, we construct its path to the document root element:)
        let $ancestors := $node/ancestor::*
        let $log := util:log("DEBUG", ("##$ancestors1): ", concat($node/string(), ':', $node/string-join(ancestor::*/name(.), '/'))))
        let $ancestors := 
                string-join
                (
                for $ancestor at $i in $ancestors
(:                let $log := util:log("DEBUG", ("##$ancestor---): ", $ancestor)):)
(:                let $log := util:log("DEBUG", ("##$ancestor-sibling): ", ($ancestor/preceding-sibling::*, $ancestor/following-sibling::*))):)
                return 
                    concat
                    (
(:                        the ancestor qname:)
                        name($ancestor)
                        ,
(:                        any attribute attached to the node if it is an element, expressed as as a predicate:)
                        string-join
                        (
                            let $attributes := $ancestor/attribute()
                            let $log := util:log("DEBUG", ("##attributes): ", string-join($attributes, ' | ')))
                            let $sibling-attributes := ($ancestor/preceding-sibling::*[name($ancestor)]/attribute(), $ancestor/following-sibling::*[name($ancestor)]/attribute())
                            let $log := util:log("DEBUG", ("##$sibling-attributes1): ", string-join($sibling-attributes, ' | ')))
                            let $missing-sibling-attributes := $sibling-attributes except $attributes
                            let $log := util:log("DEBUG", ("##$sibling-attributes2): ", string-join($sibling-attributes, ' | ')))
                            let $attributes := 
                                for $attribute in $attributes
                                return concat('[@', name($attribute), ']')
                            let $missing-sibling-attributes := 
                                for $missing-sibling-attribute in $missing-sibling-attributes
                                    return concat('[not(@', name($missing-sibling-attribute), ')]')
                            return 
                                concat(string-join($attributes), string-join($missing-sibling-attributes))
                        ,
(:                        in the case of mixed contents, any text node or element node children, expressed as a predicate:)
                        if ($ancestor/node() instance of text() and $ancestor/node() instance of element())
                        then concat('[text()][', name($ancestor), ']')
                        else 
(:                            then check for text nodes separately, as predicate:)
                            if ($ancestor/node() instance of text())
                            then '[text()]'
                            else 
(:                                and for element nodes separately, as predicate:)
                                if ($ancestor/node() instance of element())
                                then concat('[', name($ancestor), ']')
                                else 'XXX'
                )
                    , if ($i eq count($ancestors)) then '' else '/'
                    )
                )
        let $node-type :=      
                  if ($node instance of text())
                  then 'text()'
                  else
                      if ($node instance of element() and not($node/attribute()))
                      then name($node)
                      else 
                          if ($node instance of attribute())
                            then ''
(:                                concat('[@', name($node), ']/'):)
                      
                          else '[not(attribute())]'
                        
            
        return 
            if ($ancestors)
            then concat(
                $ancestors, 
                if ($node-type) then '/' else '', 
                $node-type)
            else ''
    let $paths := distinct-values($paths)
    return
        <paths>
            {
            for $path in $paths
            where string-length($path)
            order by $path
            return
                <path>{$path}</path>
            }
        </paths>
