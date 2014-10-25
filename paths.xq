xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:build-paths($doc as element()*, $attributes-to-suppress as xs:string*, $attributes-with-value-output as xs:string*) as element()* {
    let $paths :=
        (:we gather all nodes in the document:)
        let $nodes := ($doc//element(), $doc//attribute(), $doc//text())
        return
            for $node in $nodes
            (:for each node, we construct its path to the document root element:)
            let $ancestors := $node/ancestor::*
            let $ancestors :=
                string-join
                (
                for $ancestor at $i in $ancestors
                return
                    (:construct the unique path by concatenating …:)
                    concat
                    (
                    (:the the ancestor qname,:)
                    name($ancestor)
                    ,
                    (:any attribute attached to element nodes, expressed as as a predicate:)
                    (:any attribute attached to sibling elements that is not attached to the ancestor in question, expressed as a negative predicate:)
                    string-join
                    (
                    (:get the ancestor attributes:)
                    let $attributes := $ancestor/attribute()
                    (:get the attributes of ancestor sibling with the same name:)
                    let $siblings := ($ancestor/preceding-sibling::*, $ancestor/following-sibling::*)
                    (:let $log := util:log("DEBUG", ("##$siblings1): ", string-join(for $sibling in $siblings return name($sibling), ' | '))):)
                    let $same-name-siblings := 
                        for $sibling in $siblings
                        where name($sibling) eq name($ancestor)
                        return $sibling
                    (:let $log := util:log("DEBUG", ("##$ancestor): ", name($ancestor))):)
                    (:let $log := util:log("DEBUG", ("##$siblings2): ", string-join(for $sibling in $siblings return name($sibling), ' | '))):)
                    let $same-name-sibling-attributes := 
                        for $same-name-sibling in $same-name-siblings
                        return $same-name-sibling/attribute()
                    (:let $log := util:log("DEBUG", ("##$same-name-sibling-attributes): ", string-join($same-name-sibling-attributes))):)
                    (:filter away the attributes of same-name siblings that are the same as the ancestor attribute:)
                    let $attribute-names := 
                        for $attribute in $attributes
                        return name($attribute)
                    (:let $log := util:log("DEBUG", ("##$attributes): ", string-join($attributes))):)
                    let $missing-same-name-sibling-attributes := 
                        for $same-name-sibling-attribute in $same-name-sibling-attributes
                        return 
                            if (name($same-name-sibling-attribute) = $attribute-names)
                            then ()
                            else $same-name-sibling-attribute
                    (:let $log := util:log("DEBUG", ("##$missing-same-name-sibling-attributes): ", string-join($missing-same-name-sibling-attributes))):)
                    (:format attributes as predicates:)
                    let $attributes :=
                        for $attribute in $attributes
                        where not(name($attribute) =  $attributes-to-suppress)
                        return concat('[@', name($attribute), if (name($attribute) = $attributes-with-value-output) then concat('=', '"', $attribute/string(), '"', ']') else ']')
                    (:format missing attributes as negative predicates:)
                    let $missing-same-name-sibling-attributes :=
                        for $missing-sibling-attribute in $missing-same-name-sibling-attributes
                        return concat('[not(@', name($missing-sibling-attribute), ')]')
                    let $missing-same-name-sibling-attributes := distinct-values($missing-same-name-sibling-attributes)
                    return
                        concat(string-join($attributes), string-join($missing-same-name-sibling-attributes))
                    ,
                    (:in the case of mixed contents, any text node or element node children, expressed as a predicate:)
                    if ($ancestor/node() instance of text() and $ancestor/node() instance of element())
                    then concat('[text()][', name($ancestor), ']')
                    else 
                        (:then check for text nodes separately, as predicate:)
                        if ($ancestor/node() instance of text())
                        then '[text()]'
                        else 
                            (:and for element nodes separately, as predicate:)
                            if ($ancestor/node() instance of element())
                            then concat('[', name($ancestor), ']')
                            else 'XXX'
                    )
                ,
                (:string-joining with a slash:)
                if ($i eq count($ancestors))
                then ''
                else '/'
                    )
                )
            (:attach the node type to the unique ancestor path:)
            let $node-type :=
                if ($node instance of text())
                then 'text()'
                else
                    if ($node instance of element())
                    then name($node)
                    else
                        if ($node instance of attribute() and not(name($node) =  $attributes-to-suppress))
                        then concat('@', name($node))
                        else ''
            (:and return the concatenation of ancestor path and node type with a slash:)
            return 
                (:if there is no ancestor path, do not attach a node type:)
                if ($ancestors)
                then concat
                    (
                    $ancestors
                    , 
                    if ($node-type) 
                    then '/' 
                    else ''
                    , 
                    $node-type
                    )
                else ''
    (:only return distinct non-empty paths:)
    let $paths-count := count($paths[string-length(.) gt 0])
    let $distinct-paths := distinct-values($paths)
    return
        <paths count="{$paths-count}">
            {
            for $path at $n in $distinct-paths
            let $count := count($paths[. eq $path])
            let $depth := count(tokenize($path, '/')) - 1
            where string-length($path)
            order by $depth, $path
            return
                <path depth="{$depth}" count="{$count}" n="{$n}">{$path}</path>
            }
        </paths>
};

let $doc := 
<doc xml:id="x">
    <a>
        <b x="1" n="7">text1<e>text2</e>text3</b>
        <b>text0</b>
        </a>
    <a u="5">
        <c>
            <d y="2" z="3">text4</d>
            </c>
    </a>
    <a>
        <c>
            <d y="4">text5<p n="6"/>text6</d>
            </c>
    </a>
</doc>

(: let $doc := doc('/db/test/test-doc.xml')//*:)
(: let $doc := doc('/db/apps/shakespeare/data/ham.xml')//tei:TEI:)
(: let $doc := doc('/db/test/abel_leibmedicus_1699.TEI-P5.xml')//tei:TEI:)

let $attributes-to-suppress := ('xml:id', 'n')
let $attributes-with-value-output := ('type')

return local:build-paths($doc, $attributes-to-suppress, $attributes-with-value-output)