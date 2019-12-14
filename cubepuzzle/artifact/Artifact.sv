grammar artifact;

{- This Silver specification does litte more than list the desired
   extensions, albeit in a somewhat stylized way.

   Files like this can easily be generated automatically from a simple
   list of the desired extensions.
 -}

import edu:umn:cs:melt:ableC:concretesyntax as cst;
import edu:umn:cs:melt:ableC:drivers:compile;


parser extendedParser :: cst:Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:search;
  edu:umn:cs:melt:exts:ableC:closure prefix with "gc";
  edu:umn:cs:melt:exts:ableC:vector;
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes;
  
  prefer edu:umn:cs:melt:exts:ableC:refCountClosure:concretesyntax:typeExpr:Closure_t
    over edu:umn:cs:melt:exts:ableC:closure:concretesyntax:typeExpr:Closure_t,
         edu:umn:cs:melt:ableC:concretesyntax:Identifier_t,
         edu:umn:cs:melt:ableC:concretesyntax:TypeName_t,
         edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationTypeExpr:TemplateTypeName_t;
  prefer edu:umn:cs:melt:exts:ableC:refCountClosure:concretesyntax:lambdaExpr:Lambda_t
    over edu:umn:cs:melt:exts:ableC:closure:concretesyntax:lambdaExpr:Lambda_t,
         edu:umn:cs:melt:ableC:concretesyntax:Identifier_t,
         edu:umn:cs:melt:ableC:concretesyntax:TypeName_t,
         edu:umn:cs:melt:exts:ableC:templating:concretesyntax:instantiationExpr:TemplateIdentifier_t;
} 

function main
IOVal<Integer> ::= args::[String] io_in::IO
{
  return driver(args, io_in, extendedParser);
}
