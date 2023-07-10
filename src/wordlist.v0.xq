(: quick and dirty word list for Frege :)
declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $dir := '/home/cmsmcq/2023/frege/text'
let $doc := doc($dir || '/Begriffsschrift.tei.xml')

for $form in $doc//text()[not(parent::tei:formula)]
             /string()
             !tokenize(., "\s")
    let $lemma := replace($form, "\P{L}+", "")
    group by $lemma
    order by count($form) descending, $lemma ascending
return <word freq="{count($form)}" lemma="{$lemma[1]}">{
  for $f2 in $form 
  let $s := string($f2)
  group by $s
  order by count($f2) descending, $s ascending
  return <form freq="{count($f2)}">{$s}</form>
}</word>