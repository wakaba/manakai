package Whatpm::HTML::ParserData;
use strict;
use warnings;
our $VERSION = '1.0';

## Adjust MathML attributes
## <http://www.whatwg.org/specs/web-apps/current-work/#adjust-mathml-attributes>.
our $MathMLAttrNameFixup = {
  definitionurl => 'definitionURL',
}; # $MathMLAttrNameFixup

## Adjust SVG attributes
## <http://www.whatwg.org/specs/web-apps/current-work/#adjust-svg-attributes>.
our $SVGAttrNameFixup = {
  attributename => 'attributeName',
  attributetype => 'attributeType',
  basefrequency => 'baseFrequency',
  baseprofile => 'baseProfile',
  calcmode => 'calcMode',
  clippathunits => 'clipPathUnits',
  contentscripttype => 'contentScriptType',
  contentstyletype => 'contentStyleType',
  diffuseconstant => 'diffuseConstant',
  edgemode => 'edgeMode',
  externalresourcesrequired => 'externalResourcesRequired',
  filterres => 'filterRes',
  filterunits => 'filterUnits',
  glyphref => 'glyphRef',
  gradienttransform => 'gradientTransform',
  gradientunits => 'gradientUnits',
  kernelmatrix => 'kernelMatrix',
  kernelunitlength => 'kernelUnitLength',
  keypoints => 'keyPoints',
  keysplines => 'keySplines',
  keytimes => 'keyTimes',
  lengthadjust => 'lengthAdjust',
  limitingconeangle => 'limitingConeAngle',
  markerheight => 'markerHeight',
  markerunits => 'markerUnits',
  markerwidth => 'markerWidth',
  maskcontentunits => 'maskContentUnits',
  maskunits => 'maskUnits',
  numoctaves => 'numOctaves',
  pathlength => 'pathLength',
  patterncontentunits => 'patternContentUnits',
  patterntransform => 'patternTransform',
  patternunits => 'patternUnits',
  pointsatx => 'pointsAtX',
  pointsaty => 'pointsAtY',
  pointsatz => 'pointsAtZ',
  preservealpha => 'preserveAlpha',
  preserveaspectratio => 'preserveAspectRatio',
  primitiveunits => 'primitiveUnits',
  refx => 'refX',
  refy => 'refY',
  repeatcount => 'repeatCount',
  repeatdur => 'repeatDur',
  requiredextensions => 'requiredExtensions',
  requiredfeatures => 'requiredFeatures',
  specularconstant => 'specularConstant',
  specularexponent => 'specularExponent',
  spreadmethod => 'spreadMethod',
  startoffset => 'startOffset',
  stddeviation => 'stdDeviation',
  stitchtiles => 'stitchTiles',
  surfacescale => 'surfaceScale',
  systemlanguage => 'systemLanguage',
  tablevalues => 'tableValues',
  targetx => 'targetX',
  targety => 'targetY',
  textlength => 'textLength',
  viewbox => 'viewBox',
  viewtarget => 'viewTarget',
  xchannelselector => 'xChannelSelector',
  ychannelselector => 'yChannelSelector',
  zoomandpan => 'zoomAndPan',
}; # $SVGAttrNameFixup

sub XLINK_NS () { q<http://www.w3.org/1999/xlink> }
sub XML_NS () { q<http://www.w3.org/XML/1998/namespace> }
sub XMLNS_NS () { q<http://www.w3.org/2000/xmlns/> }

## Adjust foreign attributes
## <http://www.whatwg.org/specs/web-apps/current-work/#adjust-foreign-attributes>.
our $ForeignAttrNamespaceFixup = {
  'xlink:actuate' => [XLINK_NS, ['xlink', 'actuate']],
  'xlink:arcrole' => [XLINK_NS, ['xlink', 'arcrole']],
  'xlink:href' => [XLINK_NS, ['xlink', 'href']],
  'xlink:role' => [XLINK_NS, ['xlink', 'role']],
  'xlink:show' => [XLINK_NS, ['xlink', 'show']],
  'xlink:title' => [XLINK_NS, ['xlink', 'title']],
  'xlink:type' => [XLINK_NS, ['xlink', 'type']],
  'xml:base' => [XML_NS, ['xml', 'base']],
  'xml:lang' => [XML_NS, ['xml', 'lang']],
  'xml:space' => [XML_NS, ['xml', 'space']],
  'xmlns' => [XMLNS_NS, [undef, 'xmlns']],
  'xmlns:xlink' => [XMLNS_NS, ['xmlns', 'xlink']],
}; # $ForeignAttrNamespaceFixup

## The rules for parsing tokens in foreign content, Any other start
## tag, An element in the SVG namespace
## <http://www.whatwg.org/specs/web-apps/current-work/#parsing-main-inforeign>.
our $SVGElementNameFixup = {
  altglyph => 'altGlyph',
  altglyphdef => 'altGlyphDef',
  altglyphitem => 'altGlyphItem',
  animatecolor => 'animateColor',
  animatemotion => 'animateMotion',
  animatetransform => 'animateTransform',
  clippath => 'clipPath',
  feblend => 'feBlend',
  fecolormatrix => 'feColorMatrix',
  fecomponenttransfer => 'feComponentTransfer',
  fecomposite => 'feComposite',
  feconvolvematrix => 'feConvolveMatrix',
  fediffuselighting => 'feDiffuseLighting',
  fedisplacementmap => 'feDisplacementMap',
  fedistantlight => 'feDistantLight',
  feflood => 'feFlood',
  fefunca => 'feFuncA',
  fefuncb => 'feFuncB',
  fefuncg => 'feFuncG',
  fefuncr => 'feFuncR',
  fegaussianblur => 'feGaussianBlur',
  feimage => 'feImage',
  femerge => 'feMerge',
  femergenode => 'feMergeNode',
  femorphology => 'feMorphology',
  feoffset => 'feOffset',
  fepointlight => 'fePointLight',
  fespecularlighting => 'feSpecularLighting',
  fespotlight => 'feSpotLight',
  fetile => 'feTile',
  feturbulence => 'feTurbulence',
  foreignobject => 'foreignObject',
  glyphref => 'glyphRef',
  lineargradient => 'linearGradient',
  radialgradient => 'radialGradient',
  #solidcolor => 'solidColor', ## NOTE: Commented in spec (SVG1.2)
  textpath => 'textPath',  
}; # $SVGElementNameFixup

require Whatpm::_NamedEntityList;
our $NamedCharRefs = $Whatpm::HTML::EntityChar;

=head1 NAME

Whatpm::HTML::ParserData - Data for HTML parser

=head1 DESCRIPTION

The C<Whatpm::HTML::ParserData> module contains data for HTML parser,
extracted from the HTML Living Standard.

=head1 VARIABLES

Following data from the HTML specification are included:

=over 4

=item $MathMLAttrNameFixup

=item $SVGAttrNameFixup

=item $ForeignAttrNamespaceFixup

=item $SVGElementNameFixup

=item $NamedCharRefs

=back

=head1 SEE ALSO

HTML Living Standard
<http://www.whatwg.org/specs/web-apps/current-work/>.

=head1 LICENSE

Copyright 2004-2011 Apple Computer, Inc., Mozilla Foundation, and
Opera Software ASA.

You are granted a license to use, reproduce and create derivative
works of this document.

=cut

1;

