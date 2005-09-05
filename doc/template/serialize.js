function SimpleXMLSerializer () {
}

SimpleXMLSerializer.prototype.writeToString = function (nodeArg) {
  var ELEMENT_NODE = 1;
  var ATTR_NODE = 2;
  var TEXT_NODE = 3;
  var CDATA_SECTION_NODE = 4;
  var PI_NODE = 7;
  var COMMENT_NODE = 8;
  var DOCUMENT_NODE = 9;
  var isHTMLDocument = false;
  var rootElement;
  if (nodeArg.ownerDocument) rootElement = nodeArg.ownerDocument.documentElement;
  if (!rootElement) { // WinIE 6
    rootElement = nodeArg;
    while (rootElement.parentNode) {
      rootElement = rootElement.parentNode;
    }
    rootElement = rootElement.documentElement;
  }
  if (!rootElement.localName && !rootElement.namespaceURI &&
      rootElement.nodeName == 'HTML') {
    isHTMLDocument = true;
  }
  var srcs = new Array (nodeArg);
  var nsbind = [{xml: 'http://www.w3.org/XML/1998/namespace',
                 xmlns: 'http://suika.fam.cx/~wakaba/-temp/2003/09/27/undef'}];
  nsbind[0][''] = '';
  var xescape = function (s) {
    return s.replace (/&/g, '&amp;')
            .replace (/</g, '&lt;')
            .replace (/>/g, '&gt;')
            .replace (/"/g, '&quot;');
  };
  var copynsbind = function (nsbind) {
    var newbind = {};
    for (var ns in nsbind) {
      newbind[ns] = nsbind[ns];
    }
    return newbind;
  };
  var copychildren = function (pNode) {
    var children = pNode.childNodes;
    var childrenLength = children ? children.length : 0;
    if (childrenLength == 0 && pNode.nodeType == ATTR_NODE) {
    // For WinIE 6 and Opera 8
      if (pNode.value) {
        return [pNode.value];
      } else {
        return [];
      }
    }
    var snapshot = [];
    for (var i = 0; i < childrenLength; i++) {
      snapshot.push (children[i]);
    }
    return snapshot;
  };
  var copychildrento = function (pNode, ary) {
    var children = pNode.childNodes;
    var childrenLength = children.length;
    for (var i = 0; i < childrenLength; i++) {
      ary.push (children[i]);
    }
    return ary;
  };
  var r = '';
  while (true) {
    var src = srcs.shift ();
    if (!src) break;
    if (src instanceof Array) {
      nsbind.pop ();  // End tag
    } else if (src instanceof String || typeof (src) == 'string') {
      r += src;
    } else {  // Node
      if (src.nodeType == ELEMENT_NODE) {
        var csrc = [];
        var etag;
        var ns = copynsbind (nsbind[nsbind.length - 1]);
        nsbind.push (ns);
        var attrr = {};
        
        var defpfx = {};
        var ansao = {};
        var nodeAttrs = src.attributes;
        var nodeAttrsLength = nodeAttrs.length;
        for (var i = 0; i < nodeAttrsLength; i++) {
          var attr = nodeAttrs[i];
          if (attr.localName == null) {
            // Non-namespace attribute
            if (attr.nodeValue) {
              if (isHTMLDocument) {
                attrr[attr.nodeName.toLowerCase ()] = copychildren (attr);
              } else {
                attrr[attr.nodeName] = copychildren (attr);
              }
            }
          } else if (attr.namespaceURI &&
                     attr.namespaceURI == 'http://www.w3.org/2000/xmlns/') {
            // Namespace attribute
            var nsuri = attr.value;
            if (attr.localName == 'xmlns') {
              // Default namespace
              ns[''] = nsuri;
              attrr['xmlns'] = copychildren (attr);
            } else {
              // Prefixed namespace
              if (nsuri.length > 0) {
                ns[attr.localName] = nsuri;
              } else {
                ns[attr.localName]
                  = 'http://suika.fam.cx/~wakaba/-temp/2003/09/27/undef';
              }
              attrr['xmlns:' + attr.localName] = copychildren (attr);
            }
          } else if (attr.namespaceURI) {
            // Global partition attribute
            var pfx;
            var ans = attr.namespaceURI;
            if (!(defpfx[ans] != null)) defpfx[ans] = null;
            PFX: {
              if (attr.prefix) {
                if (ns[attr.prefix]) {
                  if (ns[attr.prefix] == ans) {
                    // The namespace is already defined
                    pfx = attr.prefix;
                    if (!defpfx[ans]) defpfx[ans] = pfx;
                    break PFX;
                  }
                } else {
                  // The namespace prefix is not defined yet
                  pfx = attr.prefix;
                  if (!defpfx[ans]) defpfx[ans] = pfx;
                  ns[pfx] = ans;
                  attrr['xmlns:' + pfx] = [xescape (ans)];
                  break PFX;
                }
              }
              if (defpfx[ans] != null) {
                pfx = defpfx[ans];
                break PFX;
              }
            } // PFX
            if (!ansao[ans]) ansao[ans] = [];
            ansao[ans].push ([pfx, attr]);
          } else {
            // Per-element type partition attribute
            attrr[attr.localName] = copychildren (attr);
          }
        } // Attributes
        
        // Prefix for global attributes
        PFX: for (var ans in defpfx) {
          if (defpfx[ans] != null) continue PFX;
          
          // No prefix available from the attribute nodes
          
          // Available from already defined namespaces?
          P: for (var pfx in ns) {
            if (ns[pfx] != ans) continue P;
            if (pfx.length > 0) {
              defpfx[ans] = pfx;
              continue PFX;
            }
          }
          
          // Available from the element itself?
          if ((src.namespaceURI != null) &&
              (src.namespaceURI == ans) &&
              (src.prefix != null)) {
            if (ns[src.prefix] == ans) {
              // The namespace is already defined
              defpfx[ans] = src.prefix;
              continue PFX;
            } else {
              // The namespace is not defined yet
              defpfx[ans] = src.prefix;
              ns[defpfx[ans]] = ans;
              attrr['xmlns:' + defpfx[ans]] = [xescape (ans)];
              continue PFX;
            }
          }
          
          // No prefix is defined anywhere
          var i = 1;
          while (ns['ns' + i] != null) {i++}
          defpfx = 'ns' + i;
          ns[defpfx[ans]] = ans;
          attrr['xmlns:ns' + i] = [xescape (ans)];
        } // PFX
        
        for (var ans in ansao) {
          for (var ansn in ansao[ans]) {
            var pfx = ansao[ans][ansn][0] ? ansao[ans][ansn][0] : defpfx[ans];
            attrr[pfx + ':' + ansao[ans][ansn][1].localName]
              = copychildren (ansao[ans][ansn][1]);
          }
        }
        
        // Element type name
        if (src.localName != null) {
          if (src.namespaceURI != null) {
            if (src.prefix != null &&
                ns[src.prefix] != null &&
                ns[src.prefix] == src.namespaceURI) {
              // Non-null namespace and its prefix is defined
              r += '<' + src.prefix + ':' + src.localName;
              etag = '</' + src.prefix + ':' + src.localName + '>';
            } else if (src.prefix != null &&
                       ns[src.prefix] == null) {
              attrr['xmlns:' + src.prefix] = [xescape (src.namespaceURI)];
              ns[src.prefix] = src.namespaceURI;
              r += '<' + src.prefix + ':' + src.localName;
              etag = '</' + src.prefix + ':' + src.localName + '>';
            } else {
              PFX0: {
                // Non-null namespace and its prefix is not defined
                // but is already declared as a namespace attribute
                P0: for (var pfx in ns) {
                  if (ns[pfx] != src.namespaceURI) continue P0;
                  if (pfx.length > 0) {
                    r += '<' + pfx + ':' + src.localName;
                    etag = '</' + pfx + ':' + src.localName + '>';
                  } else {
                    r += '<' + src.localName;
                    etag = '</' + src.localName + '>';
                  }
                  break PFX0;
                }
              
                // Non-null namespace and its prefix is not defined anywhere
                var i = 1;
                while (ns['ns' + i] != null) i++;
                ns['ns' + i] = src.namespaceURI;
                attrr['xmlns:ns' + i] = [xescape (src.namespaceURI)];
                r += '<ns' + i + ':' + src.localName;
                etag = '</ns' + i + ':' + src.localName + '>';
              } // PFX0
            }
          } else {
            // Null-namespace
            if (ns[''] != '') {
              // The default namespace is not the null-namespace
              ns[''] = '';
              attrr['xmlns'] = [''];
            }
            r += '<' + src.localName;
            etag = '</' + src.localName + '>';
          }
        } else {
          // Non-namespace node
          if (isHTMLDocument) {
            r += '<' + src.nodeName.toLowerCase ();
            etag = '</' + src.nodeName.toLowerCase () + '>';
          } else {
            r += '<' + src.nodeName;
            etag = '</' + src.nodeName + '>';
          }
        }
        
        // The attribute specifications
        for (var an in attrr) {
          csrc.push (' ' + an + '="');
          for (var i = 0; i < attrr[an].length; i++) {
            csrc.push (attrr[an][i]);
          }
          csrc.push ('"');
        }
        
        // The child nodes
        if (src.hasChildNodes ()) {
          csrc.push ('>');
          copychildrento (src, csrc);
          csrc.push (etag, []);
        } else if (this.UseEmptyElemTag[src.namespaceURI] &&
                   this.UseEmptyElemTag[src.namespaceURI]
                                     [src.localName ? src.localName : src.nodeName]) {
          csrc.push (' />');
          nsbind.shift ();
        } else {
          csrc.push ('>' + etag, []);
        }
        for (var i = csrc.length - 1; i >= 0; i--) {
          srcs.unshift (csrc[i]);
        }
        csrc = [];
      } else if (src.nodeType == TEXT_NODE) {;
        r += xescape (src.data);
      } else if (src.nodeType == CDATA_SECTION_NODE) {
        r += '<![CDATA[' + src.data.replace (/]]>/g, ']]]]>&gt;<![CDATA[') + ']]>';
      } else if (src.nodeType == PI_NODE) {
        r += '<?' + src.target;
        if (src.data != null && src.data.length > 0) {
          r += ' ' + src.data.replace (/\?>/g, '?&gt;');
        }
        r += '?>';
      } else if (src.nodeType == COMMENT_NODE) {
        r += '<!--' + src.data.replace (/--/g, '- - ') + '-->';
      } else if (src.nodeType == DOCUMENT_NODE) {
        var children = src.childNodes;
        var childrenLength = children.length;
        for (var i = 0; i < childrenLength; i++) {
          srcs.unshift (children[i]);
          srcs.unshift ("\n");
        }
      } // nodeType
    }
  }
  return r;
};
SimpleXMLSerializer.prototype.UseEmptyElemTag = {};
SimpleXMLSerializer.prototype.UseEmptyElemTag['http://www.w3.org/1999/xhtml'] = {
  base: true,
  basefont: true,
  bgsound: true,
  br: true,
  frame: true,
  img: true,
  input: true,
  isindex: true,
  link: true,
  meta: true,
  nextid: true,
  wbr: true
};

/* Revision: $Date: 2005/09/05 15:09:58 $ */

/* ***** BEGIN LICENSE BLOCK *****
 * Copyright 2005 Wakaba <w@suika.fam.cx>.  All rights reserved.
 *
 * This program is free software; you can redistribute it and/or 
 * modify it under the same terms as Perl itself.
 *
 * Alternatively, the contents of this file may be used 
 * under the following terms (the "MPL/GPL/LGPL"), 
 * in which case the provisions of the MPL/GPL/LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of the MPL/GPL/LGPL, and not to allow others to
 * use your version of this file under the terms of the Perl, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the MPL/GPL/LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the Perl or the MPL/GPL/LGPL.
 *
 * "MPL/GPL/LGPL":
 *
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * <http://www.mozilla.org/MPL/>
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is manakai SimpleXMLSerializer code.
 *
 * The Initial Developer of the Original Code is Wakaba.
 * Portions created by the Initial Developer are Copyright (C) 2005
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Wakaba <w@suika.fam.cx>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the LGPL or the GPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */
 