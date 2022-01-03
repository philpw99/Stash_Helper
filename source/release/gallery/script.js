/*!
 * lightgallery | 2.0.0-beta.3 | May 4th 2021
 * http://sachinchoolur.github.io/lightGallery/
 * Copyright (c) 2020 Sachin Neravath;
 * @license GPLv3
 */

(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define(factory) :
    (global.lightGallery = factory());
}(this, (function () { 'use strict';

    /*! *****************************************************************************
    Copyright (c) Microsoft Corporation.

    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
    REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
    INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
    LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
    OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
    PERFORMANCE OF THIS SOFTWARE.
    ***************************************************************************** */

    var __assign = function() {
        __assign = Object.assign || function __assign(t) {
            for (var s, i = 1, n = arguments.length; i < n; i++) {
                s = arguments[i];
                for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
            }
            return t;
        };
        return __assign.apply(this, arguments);
    };

    function __spreadArrays() {
        for (var s = 0, i = 0, il = arguments.length; i < il; i++) s += arguments[i].length;
        for (var r = Array(s), k = 0, i = 0; i < il; i++)
            for (var a = arguments[i], j = 0, jl = a.length; j < jl; j++, k++)
                r[k] = a[j];
        return r;
    }

    (function () {
        if (typeof window.CustomEvent === 'function')
            return false;
        function CustomEvent(event, params) {
            params = params || { bubbles: false, cancelable: false, detail: null };
            var evt = document.createEvent('CustomEvent');
            evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
            return evt;
        }
        window.CustomEvent = CustomEvent;
    })();
    (function () {
        if (!Element.prototype.matches) {
            Element.prototype.matches =
                Element.prototype.msMatchesSelector ||
                    Element.prototype.webkitMatchesSelector;
        }
    })();
    var lgQuery = /** @class */ (function () {
        function lgQuery(selector) {
            this.cssVenderPrefixes = [
                'TransitionDuration',
                'TransitionTimingFunction',
                'Transform',
                'Transition',
            ];
            this.selector = this._getSelector(selector);
            this.firstElement = this._getFirstEl();
            return this;
        }
        lgQuery.generateUUID = function () {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
                var r = (Math.random() * 16) | 0, v = c == 'x' ? r : (r & 0x3) | 0x8;
                return v.toString(16);
            });
        };
        lgQuery.prototype._getSelector = function (selector, context) {
            if (context === void 0) { context = document; }
            if (typeof selector !== 'string') {
                return selector;
            }
            context = context || document;
            var fl = selector.substring(0, 1);
            if (fl === '#') {
                return context.querySelector(selector);
            }
            else {
                return context.querySelectorAll(selector);
            }
        };
        lgQuery.prototype._each = function (func) {
            if (!this.selector) {
                return this;
            }
            if (this.selector.length !== undefined) {
                [].forEach.call(this.selector, func);
            }
            else {
                func(this.selector, 0);
            }
            return this;
        };
        lgQuery.prototype._setCssVendorPrefix = function (el, cssProperty, value) {
            // prettier-ignore
            var property = cssProperty.replace(/-([a-z])/gi, function (s, group1) {
                return group1.toUpperCase();
            });
            if (this.cssVenderPrefixes.indexOf(property) !== -1) {
                el.style[property.charAt(0).toLowerCase() + property.slice(1)] = value;
                el.style['webkit' + property] = value;
                el.style['moz' + property] = value;
                el.style['ms' + property] = value;
                el.style['o' + property] = value;
            }
            else {
                el.style[property] = value;
            }
        };
        lgQuery.prototype._getFirstEl = function () {
            if (this.selector && this.selector.length !== undefined) {
                return this.selector[0];
            }
            else {
                return this.selector;
            }
        };
        lgQuery.prototype.isEventMatched = function (event, eventName) {
            var eventNamespace = eventName.split('.');
            return event
                .split('.')
                .filter(function (e) { return e; })
                .every(function (e) {
                return eventNamespace.indexOf(e) !== -1;
            });
        };
        lgQuery.prototype.attr = function (attr, value) {
            if (value === undefined) {
                if (!this.firstElement) {
                    return '';
                }
                return this.firstElement.getAttribute(attr);
            }
            this._each(function (el) {
                el.setAttribute(attr, value);
            });
            return this;
        };
        lgQuery.prototype.find = function (selector) {
            return $LG(this._getSelector(selector, this.selector));
        };
        lgQuery.prototype.first = function () {
            if (this.selector && this.selector.length !== undefined) {
                return $LG(this.selector[0]);
            }
            else {
                return $LG(this.selector);
            }
        };
        lgQuery.prototype.eq = function (index) {
            return $LG(this.selector[index]);
        };
        lgQuery.prototype.parent = function () {
            return $LG(this.selector.parentElement);
        };
        lgQuery.prototype.get = function () {
            return this._getFirstEl();
        };
        lgQuery.prototype.removeAttr = function (attributes) {
            var attrs = attributes.split(' ');
            this._each(function (el) {
                attrs.forEach(function (attr) { return el.removeAttribute(attr); });
            });
            return this;
        };
        lgQuery.prototype.wrap = function (className) {
            if (!this.firstElement) {
                return this;
            }
            var wrapper = document.createElement('div');
            wrapper.className = className;
            this.firstElement.parentNode.insertBefore(wrapper, this.firstElement);
            this.firstElement.parentNode.removeChild(this.firstElement);
            wrapper.appendChild(this.firstElement);
            return this;
        };
        lgQuery.prototype.addClass = function (classNames) {
            if (classNames === void 0) { classNames = ''; }
            this._each(function (el) {
                // IE doesn't support multiple arguments
                classNames.split(' ').forEach(function (className) {
                    el.classList.add(className);
                });
            });
            return this;
        };
        lgQuery.prototype.removeClass = function (classNames) {
            this._each(function (el) {
                // IE doesn't support multiple arguments
                classNames.split(' ').forEach(function (className) {
                    el.classList.remove(className);
                });
            });
            return this;
        };
        lgQuery.prototype.hasClass = function (className) {
            if (!this.firstElement) {
                return false;
            }
            return this.firstElement.classList.contains(className);
        };
        lgQuery.prototype.hasAttribute = function (attribute) {
            if (!this.firstElement) {
                return false;
            }
            return this.firstElement.hasAttribute(attribute);
        };
        lgQuery.prototype.toggleClass = function (className) {
            if (!this.firstElement) {
                return this;
            }
            if (this.hasClass(className)) {
                this.removeClass(className);
            }
            else {
                this.addClass(className);
            }
            return this;
        };
        lgQuery.prototype.css = function (property, value) {
            var _this = this;
            this._each(function (el) {
                _this._setCssVendorPrefix(el, property, value);
            });
            return this;
        };
        // Need to pass separate namespaces for separate elements
        lgQuery.prototype.on = function (events, listener) {
            var _this = this;
            if (!this.selector) {
                return this;
            }
            events.split(' ').forEach(function (event) {
                if (!Array.isArray(lgQuery.eventListeners[event])) {
                    lgQuery.eventListeners[event] = [];
                }
                lgQuery.eventListeners[event].push(listener);
                _this.selector.addEventListener(event.split('.')[0], listener);
            });
            return this;
        };
        // @todo - test this
        lgQuery.prototype.once = function (event, listener) {
            var _this = this;
            this.on(event, function () {
                _this.off(event);
                listener(event);
            });
            return this;
        };
        lgQuery.prototype.off = function (event) {
            var _this = this;
            if (!this.selector) {
                return this;
            }
            Object.keys(lgQuery.eventListeners).forEach(function (eventName) {
                if (_this.isEventMatched(event, eventName)) {
                    lgQuery.eventListeners[eventName].forEach(function (listener) {
                        _this.selector.removeEventListener(eventName.split('.')[0], listener);
                    });
                    lgQuery.eventListeners[eventName] = [];
                }
            });
            return this;
        };
        lgQuery.prototype.trigger = function (event, detail) {
            if (!this.firstElement) {
                return this;
            }
            var customEvent = new CustomEvent(event.split('.')[0], {
                detail: detail || null,
            });
            this.firstElement.dispatchEvent(customEvent);
            return this;
        };
        // Does not support IE
        lgQuery.prototype.load = function (url) {
            var _this = this;
            fetch(url).then(function (res) {
                _this.selector.innerHTML = res;
            });
            return this;
        };
        lgQuery.prototype.html = function (html) {
            if (html === undefined) {
                if (!this.firstElement) {
                    return '';
                }
                return this.firstElement.innerHTML;
            }
            this._each(function (el) {
                el.innerHTML = html;
            });
            return this;
        };
        lgQuery.prototype.append = function (html) {
            this._each(function (el) {
                if (typeof html === 'string') {
                    el.insertAdjacentHTML('beforeend', html);
                }
                else {
                    el.appendChild(html);
                }
            });
            return this;
        };
        lgQuery.prototype.prepend = function (html) {
            this._each(function (el) {
                el.insertAdjacentHTML('afterbegin', html);
            });
            return this;
        };
        lgQuery.prototype.remove = function () {
            this._each(function (el) {
                el.parentNode.removeChild(el);
            });
            return this;
        };
        lgQuery.prototype.empty = function () {
            this._each(function (el) {
                el.innerHTML = '';
            });
            return this;
        };
        lgQuery.prototype.scrollTop = function (scrollTop) {
            if (scrollTop !== undefined) {
                document.body.scrollTop = scrollTop;
                document.documentElement.scrollTop = scrollTop;
                return this;
            }
            else {
                return (window.pageYOffset ||
                    document.documentElement.scrollTop ||
                    document.body.scrollTop ||
                    0);
            }
        };
        lgQuery.prototype.scrollLeft = function (scrollLeft) {
            if (scrollLeft !== undefined) {
                document.body.scrollLeft = scrollLeft;
                document.documentElement.scrollLeft = scrollLeft;
                return this;
            }
            else {
                return (window.pageXOffset ||
                    document.documentElement.scrollLeft ||
                    document.body.scrollLeft ||
                    0);
            }
        };
        lgQuery.prototype.offset = function () {
            if (!this.firstElement) {
                return {
                    left: 0,
                    top: 0,
                };
            }
            var rect = this.firstElement.getBoundingClientRect();
            var bodyMarginLeft = $LG('body').style().marginLeft;
            // Minus body margin - https://stackoverflow.com/questions/30711548/is-getboundingclientrect-left-returning-a-wrong-value
            return {
                left: rect.left - parseFloat(bodyMarginLeft) + this.scrollLeft(),
                top: rect.top + this.scrollTop(),
            };
        };
        lgQuery.prototype.style = function () {
            if (!this.firstElement) {
                return {};
            }
            return (this.firstElement.currentStyle ||
                window.getComputedStyle(this.firstElement));
        };
        // Width without padding and border even if box-sizing is used.
        lgQuery.prototype.width = function () {
            var style = this.style();
            return (this.firstElement.clientWidth -
                parseFloat(style.paddingLeft) -
                parseFloat(style.paddingRight));
        };
        // Height without padding and border even if box-sizing is used.
        lgQuery.prototype.height = function () {
            var style = this.style();
            return (this.firstElement.clientHeight -
                parseFloat(style.paddingTop) -
                parseFloat(style.paddingBottom));
        };
        lgQuery.eventListeners = {};
        return lgQuery;
    }());
    function $LG(selector) {
        return new lgQuery(selector);
    }

    var defaultDynamicOptions = [
        'src',
        'sources',
        'subHtml',
        'subHtmlUrl',
        'html',
        'video',
        'poster',
        'slideName',
        'responsive',
        'srcset',
        'sizes',
        'iframe',
        'downloadUrl',
        'width',
        'facebookShareUrl',
        'tweetText',
        'iframeTitle',
        'twitterShareUrl',
        'pinterestShareUrl',
        'pinterestText',
        'fbHtml',
        'disqusIdentifier',
        'disqusUrl',
    ];
    // Convert html data-attribute to camalcase
    function convertToData(attr) {
        // FInd a way for lgsize
        if (attr === 'href') {
            return 'src';
        }
        attr = attr.replace('data-', '');
        attr = attr.charAt(0).toLowerCase() + attr.slice(1);
        attr = attr.replace(/-([a-z])/g, function (g) { return g[1].toUpperCase(); });
        return attr;
    }
    var utils = {
        /**
         * get possible width and height from the lgSize attribute. Used for ZoomFromOrigin option
         */
        getSize: function (el, container, spacing, defaultLgSize) {
            if (spacing === void 0) { spacing = 0; }
            var LGel = $LG(el);
            var lgSize = LGel.attr('data-lg-size') || defaultLgSize;
            if (!lgSize) {
                return;
            }
            var isResponsiveSizes = lgSize.split(',');
            // if at-least two viewport sizes are available
            if (isResponsiveSizes[1]) {
                var wWidth = window.innerWidth;
                for (var i = 0; i < isResponsiveSizes.length; i++) {
                    var size_1 = isResponsiveSizes[i];
                    var responsiveWidth = parseInt(size_1.split('-')[2], 10);
                    if (responsiveWidth > wWidth) {
                        lgSize = size_1;
                        break;
                    }
                    // take last item as last option
                    if (i === isResponsiveSizes.length - 1) {
                        lgSize = size_1;
                    }
                }
            }
            var size = lgSize.split('-');
            var width = parseInt(size[0], 10);
            var height = parseInt(size[1], 10);
            var cWidth = container.width();
            var cHeight = container.height() - spacing;
            var maxWidth = Math.min(cWidth, width);
            var maxHeight = Math.min(cHeight, height);
            var ratio = Math.min(maxWidth / width, maxHeight / height);
            return { width: width * ratio, height: height * ratio };
        },
        /**
         * @desc Get transform value based on the imageSize. Used for ZoomFromOrigin option
         * @param {jQuery Element}
         * @returns {String} Transform CSS string
         */
        getTransform: function (el, container, top, bottom, imageSize) {
            if (!imageSize) {
                return;
            }
            var LGel = $LG(el).find('img').first();
            var containerRect = container.get().getBoundingClientRect();
            var wWidth = containerRect.width;
            // using innerWidth to include mobile safari bottom bar
            var wHeight = container.height() - (top + bottom);
            var elWidth = LGel.width();
            var elHeight = LGel.height();
            var elStyle = LGel.style();
            var x = (wWidth - elWidth) / 2 -
                LGel.offset().left +
                (parseFloat(elStyle.paddingLeft) || 0) +
                (parseFloat(elStyle.borderLeft) || 0) +
                $LG(window).scrollLeft() +
                containerRect.left;
            var y = (wHeight - elHeight) / 2 -
                LGel.offset().top +
                (parseFloat(elStyle.paddingTop) || 0) +
                (parseFloat(elStyle.borderTop) || 0) +
                $LG(window).scrollTop() +
                top;
            var scX = elWidth / imageSize.width;
            var scY = elHeight / imageSize.height;
            var transform = 'translate3d(' +
                (x *= -1) +
                'px, ' +
                (y *= -1) +
                'px, 0) scale3d(' +
                scX +
                ', ' +
                scY +
                ', 1)';
            return transform;
        },
        getIframeMarkup: function (src, iframeWidth, iframeHeight, iframeTitle) {
            var title = iframeTitle ? 'title="' + iframeTitle + '"' : '';
            return "<div class=\"lg-video-cont lg-has-iframe\" style=\"width:" + iframeWidth + "; height: " + iframeHeight + "\">\n                    <iframe class=\"lg-object\" frameborder=\"0\" " + title + " src=\"" + src + "\"  allowfullscreen=\"true\"></iframe>\n                </div>";
        },
        getImgMarkup: function (index, src, altAttr, srcset, sizes, sources) {
            var srcsetAttr = srcset ? "srcset=" + srcset : '';
            var sizesAttr = sizes ? "sizes=" + sizes : '';
            var imgMarkup = "<img " + altAttr + " " + srcsetAttr + "  " + sizesAttr + " class=\"lg-object lg-image\" data-index=\"" + index + "\" src=\"" + src + "\" />";
            var sourceTag = '';
            if (sources) {
                var sourceObj = typeof sources === 'string' ? JSON.parse(sources) : sources;
                sourceTag = sourceObj.map(function (source) {
                    var attrs = '';
                    Object.keys(source).forEach(function (key) {
                        // Do not remove the first space as it is required to separate the attributes
                        attrs += " " + key + "=\"" + source[key] + "\"";
                    });
                    return "<source " + attrs + "></source>";
                });
            }
            return "" + sourceTag + imgMarkup;
        },
        // Get src from responsive src
        getResponsiveSrc: function (srcItms) {
            var rsWidth = [];
            var rsSrc = [];
            var src = '';
            for (var i = 0; i < srcItms.length; i++) {
                var _src = srcItms[i].split(' ');
                // Manage empty space
                if (_src[0] === '') {
                    _src.splice(0, 1);
                }
                rsSrc.push(_src[0]);
                rsWidth.push(_src[1]);
            }
            var wWidth = window.innerWidth;
            for (var j = 0; j < rsWidth.length; j++) {
                if (parseInt(rsWidth[j], 10) > wWidth) {
                    src = rsSrc[j];
                    break;
                }
            }
            return src;
        },
        isImageLoaded: function (img) {
            if (!img)
                return false;
            // During the onload event, IE correctly identifies any images that
            // weren�t downloaded as not complete. Others should too. Gecko-based
            // browsers act like NS4 in that they report this incorrectly.
            if (!img.complete) {
                return false;
            }
            // However, they do have two very useful properties: naturalWidth and
            // naturalHeight. These give the true size of the image. If it failed
            // to load, either of these should be zero.
            if (img.naturalWidth === 0) {
                return false;
            }
            // No other way of checking: assume it�s ok.
            return true;
        },
        getVideoPosterMarkup: function (_poster, dummyImg, videoContStyle, _isVideo) {
            var videoClass = '';
            if (_isVideo && _isVideo.youtube) {
                videoClass = 'lg-has-youtube';
            }
            else if (_isVideo && _isVideo.vimeo) {
                videoClass = 'lg-has-vimeo';
            }
            else {
                videoClass = 'lg-has-html5';
            }
            return "<div class=\"lg-video-cont " + videoClass + "\" style=\"" + videoContStyle + "\">\n                <div class=\"lg-video-play-button\">\n                <svg\n                    viewBox=\"0 0 20 20\"\n                    preserveAspectRatio=\"xMidYMid\"\n                    focusable=\"false\"\n                    aria-labelledby=\"Play video\"\n                    role=\"img\"\n                    class=\"lg-video-play-icon\"\n                >\n                    <title>Play video</title>\n                    <polygon class=\"lg-video-play-icon-inner\" points=\"1,0 20,10 1,20\"></polygon>\n                </svg>\n                <svg class=\"lg-video-play-icon-bg\" viewBox=\"0 0 50 50\" focusable=\"false\">\n                    <circle cx=\"50%\" cy=\"50%\" r=\"20\"></circle></svg>\n                <svg class=\"lg-video-play-icon-circle\" viewBox=\"0 0 50 50\" focusable=\"false\">\n                    <circle cx=\"50%\" cy=\"50%\" r=\"20\"></circle>\n                </svg>\n            </div>\n            " + (dummyImg || '') + "\n            <img class=\"lg-object lg-video-poster\" src=\"" + _poster + "\" />\n        </div>";
        },
        /**
         * @desc Create dynamic elements array from gallery items when dynamic option is false
         * It helps to avoid frequent DOM interaction
         * and avoid multiple checks for dynamic elments
         *
         * @returns {Array} dynamicEl
         */
        getDynamicOptions: function (items, extraProps, getCaptionFromTitleOrAlt, exThumbImage) {
            var dynamicElements = [];
            var availableDynamicOptions = __spreadArrays(defaultDynamicOptions, extraProps);
            [].forEach.call(items, function (item) {
                var dynamicEl = {};
                for (var i = 0; i < item.attributes.length; i++) {
                    var attr = item.attributes[i];
                    if (attr.specified) {
                        var dynamicAttr = convertToData(attr.name);
                        var label = '';
                        if (availableDynamicOptions.indexOf(dynamicAttr) > -1) {
                            label = dynamicAttr;
                        }
                        if (label) {
                            dynamicEl[label] = attr.value;
                        }
                    }
                }
                var currentItem = $LG(item);
                var alt = currentItem.find('img').first().attr('alt');
                var title = currentItem.attr('title');
                var thumb = exThumbImage
                    ? currentItem.attr(exThumbImage)
                    : currentItem.find('img').first().attr('src');
                dynamicEl.thumb = thumb;
                if (getCaptionFromTitleOrAlt && !dynamicEl.subHtml) {
                    dynamicEl.subHtml = title || alt || '';
                }
                dynamicEl.alt = alt || title || '';
                dynamicElements.push(dynamicEl);
            });
            return dynamicElements;
        },
        isMobile: function () {
            var isMobile = false;
            (function (a) {
                if (/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino|android|ipad|playbook|silk/i.test(a) ||
                    /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0, 4)))
                    isMobile = true;
            })(navigator.userAgent || navigator.vendor || window.opera);
            return isMobile;
        },
    };

    var lightGallerySettings = {
        mode: 'lg-slide',
        easing: 'ease',
        speed: 400,
        height: '100%',
        width: '100%',
        addClass: '',
        startClass: 'lg-start-zoom',
        backdropDuration: 300,
        container: document.body,
        startAnimationDuration: 400,
        zoomFromOrigin: true,
        hideBarsDelay: 0,
        showBarsAfter: 10000,
        slideDelay: 0,
        supportLegacyBrowser: true,
        allowMediaOverlap: false,
        videoMaxSize: '1280-720',
        defaultCaptionHeight: 0,
        ariaLabelledby: '',
        ariaDescribedby: '',
        closable: true,
        swipeToClose: true,
        closeOnTap: true,
        showCloseIcon: true,
        showMaximizeIcon: false,
        loop: true,
        escKey: true,
        keyPress: true,
        controls: true,
        slideEndAnimation: true,
        hideControlOnEnd: false,
        mousewheel: false,
        getCaptionFromTitleOrAlt: true,
        appendSubHtmlTo: '.lg-sub-html',
        subHtmlSelectorRelative: false,
        preload: 2,
        numberOfSlideItemsInDom: 10,
        showAfterLoad: true,
        selector: '',
        selectWithin: '',
        nextHtml: '',
        prevHtml: '',
        index: 0,
        iframeWidth: '100%',
        iframeHeight: '100%',
        download: true,
        counter: true,
        appendCounterTo: '.lg-toolbar',
        swipeThreshold: 50,
        enableSwipe: true,
        enableDrag: true,
        dynamic: false,
        dynamicEl: [],
        extraProps: [],
        galleryId: '1',
        customSlideName: false,
        exThumbImage: '',
        isMobile: undefined,
        mobileSettings: {
            controls: false,
            showCloseIcon: false,
            download: false,
        },
        plugins: [],
    };

    /**
     * List of lightGallery events
     * All events should be documented here
     * Below interfaces are used to build the website documentations
     * */
    var lGEvents = {
        afterAppendSlide: 'lgAfterAppendSlide',
        init: 'lgInit',
        hasVideo: 'lgHasVideo',
        containerResize: 'lgContainerResize',
        updateSlides: 'lgUpdateSlides',
        afterAppendSubHtml: 'lgAfterAppendSubHtml',
        beforeOpen: 'lgBeforeOpen',
        afterOpen: 'lgAfterOpen',
        slideItemLoad: 'lgSlideItemLoad',
        beforeSlide: 'lgBeforeSlide',
        afterSlide: 'lgAfterSlide',
        posterClick: 'lgPosterClick',
        dragStart: 'lgDragStart',
        dragMove: 'lgDragMove',
        dragEnd: 'lgDragEnd',
        beforeNextSlide: 'lgBeforeNextSlide',
        beforePrevSlide: 'lgBeforePrevSlide',
        beforeClose: 'lgBeforeClose',
        afterClose: 'lgAfterClose',
    };

    // @ref - https://stackoverflow.com/questions/3971841/how-to-resize-images-proportionally-keeping-the-aspect-ratio
    // @ref - https://2ality.com/2017/04/setting-up-multi-platform-packages.html
    // Unique id for each gallery
    var lgId = 0;
    var LightGallery = /** @class */ (function () {
        function LightGallery(element, options) {
            if (options === void 0) { options = {}; }
            this.lgOpened = false;
            this.index = 0;
            // lightGallery modules
            this.plugins = [];
            // false when lightGallery load first slide content;
            this.lGalleryOn = false;
            // True when a slide animation is in progress
            this.lgBusy = false;
            this.currentItemsInDom = [];
            // Scroll top value before lightGallery is opened
            this.prevScrollTop = 0;
            this.isDummyImageRemoved = false;
            this.mediaContainerPosition = {
                top: 0,
                bottom: 0,
            };
            lgId++;
            this.lgId = lgId;
            this.el = element;
            this.LGel = $LG(element);
            // lightGallery settings
            this.settings = __assign(__assign({}, lightGallerySettings), options);
            if (this.settings.isMobile &&
                typeof this.settings.isMobile === 'function'
                ? this.settings.isMobile()
                : utils.isMobile()) {
                var mobileSettings = __assign(__assign({}, this.settings.mobileSettings), options.mobileSettings);
                this.settings = __assign(__assign({}, this.settings), mobileSettings);
            }
            // When using dynamic mode, ensure dynamicEl is an array
            if (this.settings.dynamic &&
                this.settings.dynamicEl !== undefined &&
                !Array.isArray(this.settings.dynamicEl)) {
                throw 'When using dynamic mode, you must also define dynamicEl as an Array.';
            }
            if (this.settings.slideEndAnimation) {
                this.settings.hideControlOnEnd = false;
            }
            if (!this.settings.closable) {
                this.settings.swipeToClose = false;
            }
            // Need to disable zoomFromOrigin if gallery is opened from url (Hash plugin)
            // And reset it on close to get the correct value next time
            this.zoomFromOrigin = this.settings.zoomFromOrigin;
            // Gallery items
            this.galleryItems = this.getItems();
            // At the moment, Zoom from image doesn't support dynamic options
            // @todo add zoomFromOrigin support for dynamic images
            if (this.settings.dynamic) {
                this.zoomFromOrigin = false;
            }
            // settings.preload should not be grater than $item.length
            this.settings.preload = Math.min(this.settings.preload, this.galleryItems.length);
            this.init();
            return this;
        }
        LightGallery.prototype.init = function () {
            var _this = this;
            this.addSlideVideoInfo(this.galleryItems);
            var fromHash = this.buildFromHash();
            if (!fromHash) {
                this.buildStructure();
            }
            this.LGel.trigger(lGEvents.init, {
                instance: this,
            });
            if (this.settings.keyPress) {
                this.keyPress();
            }
            setTimeout(function () {
                _this.enableDrag();
                _this.enableSwipe();
            }, 50);
            if (this.galleryItems.length > 1) {
                this.arrow();
                if (this.settings.mousewheel) {
                    this.mousewheel();
                }
            }
            if (!this.settings.dynamic) {
                var _loop_1 = function (index) {
                    var element = this_1.items[index];
                    var $element = $LG(element);
                    // Using different namespace for click because click event should not unbind if selector is same object('this')
                    // @todo manage all event listners - should have namespace that represent element
                    var uuid = lgQuery.generateUUID();
                    $element
                        .attr('data-lg-id', uuid)
                        .on("click.lgcustom-item-" + uuid, function (e) {
                        e.preventDefault();
                        var currentItemIndex = _this.settings.index || index;
                        _this.openGallery(currentItemIndex, element);
                    });
                };
                var this_1 = this;
                // Using for loop instead of using bubbling as the items can be any html element.
                for (var index = 0; index < this.items.length; index++) {
                    _loop_1(index);
                }
            }
        };
        /**
         * Module constructor
         * Modules are build incrementally.
         * Gallery should be opened only once all the modules are initialized.
         * use moduleBuildTimeout to make sure this
         */
        LightGallery.prototype.buildModules = function () {
            var _this = this;
            var numberOfModules = 0;
            this.settings.plugins.forEach(function (plugin) {
                numberOfModules++;
                (function (num) {
                    setTimeout(function () {
                        _this.plugins.push(new plugin(_this, $LG));
                    }, 10 * num);
                })(numberOfModules);
            });
            return numberOfModules * 10;
        };
        LightGallery.prototype.getSlideItem = function (index) {
            return $LG(this.getSlideItemId(index));
        };
        LightGallery.prototype.getSlideItemId = function (index) {
            return "#lg-item-" + this.lgId + "-" + index;
        };
        LightGallery.prototype.getIdName = function (id) {
            return id + "-" + this.lgId;
        };
        LightGallery.prototype.getElementById = function (id) {
            return $LG("#" + this.getIdName(id));
        };
        LightGallery.prototype.buildStructure = function () {
            var _this = this;
            var container = this.$container && this.$container.get();
            if (container) {
                return 0;
            }
            var controls = '';
            var subHtmlCont = '';
            // Create controls
            if (this.settings.controls && this.galleryItems.length > 1) {
                controls = "<button type=\"button\" id=\"" + this.getIdName('lg-prev') + "\" aria-label=\"Previous slide\" class=\"lg-prev lg-icon\"> " + this.settings.prevHtml + " </button>\n                <button type=\"button\" id=\"" + this.getIdName('lg-next') + "\" aria-label=\"Next slide\" class=\"lg-next lg-icon\"> " + this.settings.nextHtml + " </button>";
            }
            if (this.settings.appendSubHtmlTo === '.lg-sub-html') {
                subHtmlCont =
                    '<div class="lg-sub-html" role="status" aria-live="polite"></div>';
            }
            var addClasses = '';
            if (this.settings.allowMediaOverlap) {
                // Do not remove space before last single quote
                addClasses += 'lg-media-overlap ';
            }
            var ariaLabelledby = this.settings.ariaLabelledby
                ? 'aria-labelledby="' + this.settings.ariaLabelledby + '"'
                : '';
            var ariaDescribedby = this.settings.ariaDescribedby
                ? 'aria-describedby="' + this.settings.ariaDescribedby + '"'
                : '';
            var containerClassName = "lg-container " + this.settings.addClass + " " + (document.body !== this.settings.container ? 'lg-inline' : '');
            var closeIcon = this.settings.closable && this.settings.showCloseIcon
                ? "<button type=\"button\" aria-label=\"Close gallery\" id=\"" + this.getIdName('lg-close') + "\" class=\"lg-close lg-icon\"></button>"
                : '';
            var maximizeIcon = this.settings.showMaximizeIcon
                ? "<button type=\"button\" aria-label=\"Toggle maximize\" id=\"" + this.getIdName('lg-maximize') + "\" class=\"lg-maximize lg-icon\"></button>"
                : '';
            var template = "\n        <div class=\"" + containerClassName + "\" id=\"" + this.getIdName('lg-container') + "\" tabindex=\"-1\" aria-modal=\"true\" " + ariaLabelledby + " " + ariaDescribedby + " role=\"dialog\"\n        >\n            <div id=\"" + this.getIdName('lg-backdrop') + "\" class=\"lg-backdrop\"></div>\n\n            <div id=\"" + this.getIdName('lg-outer') + "\" class=\"lg-outer lg-hide-items " + addClasses + " \">\n                    <div id=\"" + this.getIdName('lg-content') + "\" class=\"lg\" style=\"width: " + this.settings.width + "; height:" + this.settings.height + "\">\n                        <div id=\"" + this.getIdName('lg-inner') + "\" class=\"lg-inner\"></div>\n                        <div id=\"" + this.getIdName('lg-toolbar') + "\" class=\"lg-toolbar lg-group\">\n                        " + maximizeIcon + "\n                        " + closeIcon + "\n                    </div>\n                    " + controls + "\n                    <div id=\"" + this.getIdName('lg-components') + "\" class=\"lg-components\">\n                        " + subHtmlCont + "\n                    </div>\n                </div> \n            </div>\n        </div>\n        ";
            $LG(this.settings.container)
                .css('position', 'relative')
                .append(template);
            this.outer = this.getElementById('lg-outer');
            this.$lgContent = this.getElementById('lg-content');
            this.$lgComponents = this.getElementById('lg-components');
            this.$backdrop = this.getElementById('lg-backdrop');
            this.$container = this.getElementById('lg-container');
            this.$inner = this.getElementById('lg-inner');
            this.$toolbar = this.getElementById('lg-toolbar');
            this.$backdrop.css('transition-duration', this.settings.backdropDuration + 'ms');
            this.outer.addClass('lg-use-css3');
            // add Class for css support and transition mode
            this.outer.addClass('lg-css3');
            this.outer.addClass(this.settings.mode);
            if (this.settings.enableDrag && this.galleryItems.length > 1) {
                this.outer.addClass('lg-grab');
            }
            if (this.settings.showAfterLoad) {
                this.outer.addClass('lg-show-after-load');
            }
            this.$inner.css('transition-timing-function', this.settings.easing);
            this.$inner.css('transition-duration', this.settings.speed + 'ms');
            if (this.settings.download) {
                this.$toolbar.append("<a id=\"" + this.getIdName('lg-download') + "\" target=\"_blank\" aria-label=\"Download\" download class=\"lg-download lg-icon\"></a>");
            }
            this.counter();
            $LG(window).on("resize.lg.global" + this.lgId + " orientationchange.lg.global" + this.lgId, function () {
                _this.refreshOnResize();
            });
            this.hideBars();
            this.manageCloseGallery();
            this.toggleMaximize();
            return this.buildModules();
        };
        LightGallery.prototype.refreshOnResize = function () {
            if (this.lgOpened) {
                var currentGalleryItem = this.galleryItems[this.index];
                var videoInfo = currentGalleryItem.__slideVideoInfo;
                var _a = this.getMediaContainerPosition(), top_1 = _a.top, bottom = _a.bottom;
                this.currentImageSize = utils.getSize(this.items[this.index], this.$lgContent, top_1 + bottom, videoInfo && this.settings.videoMaxSize);
                if (videoInfo) {
                    this.resizeVideoSlide(this.index, this.currentImageSize);
                }
                if (this.zoomFromOrigin && !this.isDummyImageRemoved) {
                    var imgStyle = this.getDummyImgStyles(this.currentImageSize);
                    this.outer
                        .find('.lg-current .lg-dummy-img')
                        .first()
                        .attr('style', imgStyle);
                }
                this.LGel.trigger(lGEvents.containerResize);
            }
        };
        LightGallery.prototype.resizeVideoSlide = function (index, imageSize) {
            var lgVideoStyle = this.getVideoContStyle(imageSize);
            var currentSlide = this.getSlideItem(index);
            currentSlide.find('.lg-video-cont').attr('style', lgVideoStyle);
        };
        /**
         * Update slides dynamically.
         * Add, edit or delete slides dynamically when lightGallery is opened.
         * Modify the current gallery items and pass it via updateSlides method
         * @note
         * - Do not mutate existing lightGallery items directly.
         * - Always pass new list of gallery items
         * - You need to take care of thumbnails outside the gallery if any
         * @param items Gallery items
         * @param index After the update operation, which slide gallery should navigate to
         * @category lGPublicMethods
         * @example
         * const plugin = lightGallery();
         *
         * // Adding slides dynamically
         * let galleryItems = [
         * // Access existing lightGallery items
         * // galleryItems are automatically generated internally from the gallery HTML markup
         * // or directly from galleryItems when dynamic gallery is used
         *   ...plugin.galleryItems,
         *     ...[
         *       {
         *         src: 'img/img-1.png',
         *           thumb: 'img/thumb1.png',
         *         },
         *     ],
         *   ];
         *   plugin.updateSlides(
         *     galleryItems,
         *     plugin.index,
         *   );
         *
         *
         * // Remove slides dynamically
         * galleryItems = JSON.parse(
         *   JSON.stringify(updateSlideInstance.galleryItems),
         * );
         * galleryItems.shift();
         * updateSlideInstance.updateSlides(galleryItems, 1);
         * @see <a href="/demos/update-slides/">Demo</a>
         */
        LightGallery.prototype.updateSlides = function (items, index) {
            if (this.index > items.length - 1) {
                this.index = items.length - 1;
            }
            if (items.length === 1) {
                this.index = 0;
            }
            if (!items.length) {
                this.closeGallery();
                return;
            }
            var currentSrc = this.galleryItems[index].src;
            this.addSlideVideoInfo(items);
            this.galleryItems = items;
            this.$inner.empty();
            this.currentItemsInDom = [];
            var _index = 0;
            // Find the current index based on source value of the slide
            this.galleryItems.some(function (galleryItem, itemIndex) {
                if (galleryItem.src === currentSrc) {
                    _index = itemIndex;
                    return true;
                }
                return false;
            });
            this.currentItemsInDom = this.organizeSlideItems(_index, -1);
            this.loadContent(_index, true);
            this.getSlideItem(_index).addClass('lg-current');
            this.index = _index;
            this.updateCurrentCounter(_index);
            this.updateCounterTotal();
            this.LGel.trigger(lGEvents.updateSlides);
        };
        // Get gallery items based on multiple conditions
        LightGallery.prototype.getItems = function () {
            // Gallery items
            this.items = [];
            if (!this.settings.dynamic) {
                if (this.settings.selector === 'this') {
                    this.items.push(this.el);
                }
                else if (this.settings.selector) {
                    if (this.settings.selectWithin) {
                        var selectWithin = $LG(this.settings.selectWithin);
                        this.items = selectWithin
                            .find(this.settings.selector)
                            .get();
                    }
                    else {
                        this.items = this.el.querySelectorAll(this.settings.selector);
                    }
                }
                else {
                    this.items = this.el.children;
                }
                return utils.getDynamicOptions(this.items, this.settings.extraProps, this.settings.getCaptionFromTitleOrAlt, this.settings.exThumbImage);
            }
            else {
                return this.settings.dynamicEl || [];
            }
        };
        /**
         * Open lightGallery.
         * Open gallery with specific slide by passing index of the slide as parameter.
         * @category lGPublicMethods
         * @param {Number} index  - index of the slide
         * @param {HTMLElement} element - Which image lightGallery should zoom from
         *
         * @example
         * const $dynamicGallery = document.getElementById('dynamic-gallery-demo');
         * const dynamicGallery = lightGallery($dynamicGallery, {
         *     dynamic: true,
         *     dynamicEl: [
         *         {
         *              src: 'img/1.jpg',
         *              thumb: 'img/thumb-1.jpg',
         *              subHtml: '<h4>Image 1 title</h4><p>Image 1 descriptions.</p>',
         *         },
         *         ...
         *     ],
         * });
         * $dynamicGallery.addEventListener('click', function () {
         *     // Starts with third item.(Optional).
         *     // This is useful if you want use dynamic mode with
         *     // custom thumbnails (thumbnails outside gallery),
         *     dynamicGallery.openGallery(2);
         * });
         *
         */
        LightGallery.prototype.openGallery = function (index, element) {
            var _this = this;
            if (index === void 0) { index = this.settings.index; }
            // prevent accidental double execution
            if (this.lgOpened)
                return;
            this.lgOpened = true;
            this.outer.get().focus();
            this.outer.removeClass('lg-hide-items');
            // Add display block, but still has opacity 0
            this.$container.addClass('lg-show');
            var itemsToBeInsertedToDom = this.getItemsToBeInsertedToDom(index, index);
            this.currentItemsInDom = itemsToBeInsertedToDom;
            var items = '';
            itemsToBeInsertedToDom.forEach(function (item) {
                items = items + ("<div id=\"" + item + "\" class=\"lg-item\"></div>");
            });
            this.$inner.append(items);
            this.addHtml(index);
            var transform = '';
            this.mediaContainerPosition = this.getMediaContainerPosition();
            var _a = this.mediaContainerPosition, top = _a.top, bottom = _a.bottom;
            if (!this.settings.allowMediaOverlap) {
                this.setMediaContainerPosition(top, bottom);
            }
            if (this.zoomFromOrigin && element) {
                this.currentImageSize = utils.getSize(element, this.$lgContent, top + bottom, this.galleryItems[this.index].__slideVideoInfo &&
                    this.settings.videoMaxSize);
                transform = utils.getTransform(element, this.$lgContent, top, bottom, this.currentImageSize);
            }
            if (!this.zoomFromOrigin || !transform) {
                this.outer.addClass(this.settings.startClass);
                this.getSlideItem(index).removeClass('lg-complete');
            }
            var timeout = this.settings.zoomFromOrigin
                ? 100
                : this.settings.backdropDuration;
            setTimeout(function () {
                _this.outer.addClass('lg-components-open');
            }, timeout);
            this.LGel.trigger(lGEvents.beforeOpen);
            // add class lg-current to remove initial transition
            this.getSlideItem(index).addClass('lg-current');
            this.lGalleryOn = false;
            this.index = index;
            // Store the current scroll top value to scroll back after closing the gallery..
            this.prevScrollTop = $LG(window).scrollTop();
            setTimeout(function () {
                // Need to check both zoomFromOrigin and transform values as we need to set set the
                // default opening animation if user missed to add the lg-size attribute
                if (_this.zoomFromOrigin && transform) {
                    var currentSlide_1 = _this.getSlideItem(index);
                    currentSlide_1.css('transform', transform);
                    setTimeout(function () {
                        currentSlide_1
                            .addClass('lg-start-progress lg-start-end-progress')
                            .css('transition-duration', _this.settings.startAnimationDuration + 'ms');
                        _this.outer.addClass('lg-zoom-from-image');
                    });
                    setTimeout(function () {
                        currentSlide_1.css('transform', 'translate3d(0, 0, 0)');
                    }, 100);
                }
                setTimeout(function () {
                    _this.$backdrop.addClass('in');
                    _this.$container.addClass('lg-show-in');
                }, 10);
                // lg-visible class resets gallery opacity to 1
                if (!_this.zoomFromOrigin || !transform) {
                    setTimeout(function () {
                        _this.outer.addClass('lg-visible');
                    }, _this.settings.backdropDuration);
                }
                // initiate slide function
                _this.slide(index, false, false, false);
                _this.LGel.trigger(lGEvents.afterOpen);
            });
            $LG(document.body).addClass('lg-on');
        };
        /**
         * Note - Changing the position of the media on every slide transition creates a flickering effect.
         * Therefore, The height of the caption is calculated dynamically, only once based on the first slide caption.
         * if you have dynamic captions for each media,
         * you can provide an appropriate height for the captions via allowMediaOverlap option
         */
        LightGallery.prototype.getMediaContainerPosition = function () {
            if (this.settings.allowMediaOverlap) {
                return {
                    top: 0,
                    bottom: 0,
                };
            }
            var top = this.$toolbar.get().clientHeight || 0;
            var captionHeight = this.settings.defaultCaptionHeight ||
                this.outer.find('.lg-sub-html').get().clientHeight;
            var thumbContainer = this.outer.find('.lg-thumb-outer').get();
            var thumbHeight = thumbContainer ? thumbContainer.clientHeight : 0;
            var bottom = thumbHeight + captionHeight;
            return {
                top: top,
                bottom: bottom,
            };
        };
        LightGallery.prototype.setMediaContainerPosition = function (top, bottom) {
            if (top === void 0) { top = 0; }
            if (bottom === void 0) { bottom = 0; }
            this.$inner.css('top', top + 'px').css('bottom', bottom + 'px');
        };
        // Build Gallery if gallery id exist in the URL
        LightGallery.prototype.buildFromHash = function () {
            var _this = this;
            // if dynamic option is enabled execute immediately
            var _hash = window.location.hash;
            if (_hash.indexOf('lg=' + this.settings.galleryId) > 0) {
                // This class is used to remove the initial animation if galleryId present in the URL
                $LG(document.body).addClass('lg-from-hash');
                this.zoomFromOrigin = false;
                var index_1 = this.getIndexFromUrl(_hash);
                var openGalleryAfter = this.buildStructure();
                setTimeout(function () {
                    _this.openGallery(index_1);
                }, openGalleryAfter);
                return true;
            }
        };
        LightGallery.prototype.hideBars = function () {
            var _this = this;
            // Hide controllers if mouse doesn't move for some period
            setTimeout(function () {
                _this.outer.removeClass('lg-hide-items');
                if (_this.settings.hideBarsDelay > 0) {
                    _this.outer.on('mousemove.lg click.lg touchstart.lg', function () {
                        _this.outer.removeClass('lg-hide-items');
                        clearTimeout(_this.hideBarTimeout);
                        // Timeout will be cleared on each slide movement also
                        _this.hideBarTimeout = setTimeout(function () {
                            _this.outer.addClass('lg-hide-items');
                        }, _this.settings.hideBarsDelay);
                    });
                    _this.outer.trigger('mousemove.lg');
                }
            }, this.settings.showBarsAfter);
        };
        LightGallery.prototype.initPictureFill = function ($img) {
            if (this.settings.supportLegacyBrowser) {
                try {
                    picturefill({
                        elements: [$img.get()],
                    });
                }
                catch (e) {
                    console.warn('lightGallery :- If you want srcset or picture tag to be supported for older browser please include picturefil javascript library in your document.');
                }
            }
        };
        /**
         *  @desc Create image counter
         *  Ex: 1/10
         */
        LightGallery.prototype.counter = function () {
            if (this.settings.counter) {
                var counterHtml = "<div class=\"lg-counter\" role=\"status\" aria-live=\"polite\">\n                <span id=\"" + this.getIdName('lg-counter-current') + "\" class=\"lg-counter-current\">" + (this.index + 1) + " </span> / \n                <span id=\"" + this.getIdName('lg-counter-all') + "\" class=\"lg-counter-all\">" + this.galleryItems.length + " </span></div>";
                this.outer.find(this.settings.appendCounterTo).append(counterHtml);
            }
        };
        /**
         *  @desc add sub-html into the slide
         *  @param {Number} index - index of the slide
         */
        LightGallery.prototype.addHtml = function (index) {
            var subHtml;
            var subHtmlUrl;
            if (this.galleryItems[index].subHtmlUrl) {
                subHtmlUrl = this.galleryItems[index].subHtmlUrl;
            }
            else {
                subHtml = this.galleryItems[index].subHtml;
            }
            if (!subHtmlUrl) {
                if (subHtml) {
                    // get first letter of subhtml
                    // if first letter starts with . or # get the html form the jQuery object
                    var fL = subHtml.substring(0, 1);
                    if (fL === '.' || fL === '#') {
                        if (this.settings.subHtmlSelectorRelative &&
                            !this.settings.dynamic) {
                            subHtml = $LG(this.items)
                                .eq(index)
                                .find(subHtml)
                                .first()
                                .html();
                        }
                        else {
                            subHtml = $LG(subHtml).first().html();
                        }
                    }
                }
                else {
                    subHtml = '';
                }
            }
            if (this.settings.appendSubHtmlTo === '.lg-sub-html') {
                if (subHtmlUrl) {
                    this.outer.find('.lg-sub-html').load(subHtmlUrl);
                }
                else {
                    this.outer.find('.lg-sub-html').html(subHtml);
                }
            }
            else {
                var currentSlide = $LG(this.getSlideItemId(index));
                if (subHtmlUrl) {
                    currentSlide.load(subHtmlUrl);
                }
                else {
                    currentSlide.append("<div class=\"lg-sub-html\">" + subHtml + "</div>");
                }
            }
            // Add lg-empty-html class if title doesn't exist
            if (typeof subHtml !== 'undefined' && subHtml !== null) {
                if (subHtml === '') {
                    this.outer
                        .find(this.settings.appendSubHtmlTo)
                        .addClass('lg-empty-html');
                }
                else {
                    this.outer
                        .find(this.settings.appendSubHtmlTo)
                        .removeClass('lg-empty-html');
                }
            }
            this.LGel.trigger(lGEvents.afterAppendSubHtml, {
                index: index,
            });
        };
        /**
         *  @desc Preload slides
         *  @param {Number} index - index of the slide
         * @todo preload not working for the first slide, Also, should work for the first and last slide as well
         */
        LightGallery.prototype.preload = function (index) {
            for (var i = 1; i <= this.settings.preload; i++) {
                if (i >= this.galleryItems.length - index) {
                    break;
                }
                this.loadContent(index + i, false);
            }
            for (var j = 1; j <= this.settings.preload; j++) {
                if (index - j < 0) {
                    break;
                }
                this.loadContent(index - j, false);
            }
        };
        LightGallery.prototype.getDummyImgStyles = function (imageSize) {
            if (!imageSize)
                return '';
            return "width:" + imageSize.width + "px; \n                margin-left: -" + imageSize.width / 2 + "px;\n                margin-top: -" + imageSize.height / 2 + "px; \n                height:" + imageSize.height + "px";
        };
        LightGallery.prototype.getVideoContStyle = function (imageSize) {
            if (!imageSize)
                return '';
            return "width:" + imageSize.width + "px; \n                height:" + imageSize.height + "px";
        };
        LightGallery.prototype.getDummyImageContent = function ($currentSlide, index, alt) {
            var $currentItem;
            if (!this.settings.dynamic) {
                $currentItem = $LG(this.items).eq(index);
            }
            if ($currentItem) {
                var _dummyImgSrc = void 0;
                if (!this.settings.exThumbImage) {
                    _dummyImgSrc = $currentItem.find('img').first().attr('src');
                }
                else {
                    _dummyImgSrc = $currentItem.attr(this.settings.exThumbImage);
                }
                var imgStyle = this.getDummyImgStyles(this.currentImageSize);
                var dummyImgContent = "<img " + alt + " style=\"" + imgStyle + "\" class=\"lg-dummy-img\" src=\"" + _dummyImgSrc + "\" />";
                $currentSlide.addClass('lg-first-slide');
                return dummyImgContent;
            }
            return '';
        };
        LightGallery.prototype.setImgMarkup = function (src, $currentSlide, index) {
            var currentGalleryItem = this.galleryItems[index];
            var alt = currentGalleryItem.alt, srcset = currentGalleryItem.srcset, sizes = currentGalleryItem.sizes, sources = currentGalleryItem.sources;
            // Use the thumbnail as dummy image which will be resized to actual image size and
            // displayed on top of actual image
            var imgContent = '';
            var altAttr = alt ? 'alt="' + alt + '"' : '';
            if (!this.lGalleryOn && this.zoomFromOrigin && this.currentImageSize) {
                imgContent = this.getDummyImageContent($currentSlide, index, altAttr);
            }
            else {
                imgContent = utils.getImgMarkup(index, src, altAttr, srcset, sizes, sources);
            }
            var imgMarkup = "<picture class=\"lg-img-wrap\"> " + imgContent + "</picture>";
            $currentSlide.prepend(imgMarkup);
        };
        LightGallery.prototype.onLgObjectLoad = function ($el, index, delay, speed, dummyImageLoaded) {
            var _this = this;
            if (dummyImageLoaded) {
                this.LGel.trigger(lGEvents.slideItemLoad, {
                    index: index,
                    delay: delay || 0,
                });
            }
            $el.find('.lg-object')
                .first()
                .on('load.lg', function () {
                _this.handleLgObjectLoad($el, index, delay, speed, dummyImageLoaded);
            });
            setTimeout(function () {
                $el.find('.lg-object')
                    .first()
                    .on('error.lg', function () {
                    $el.addClass('lg-complete lg-complete_');
                    $el.html('<span class="lg-error-msg">Oops... Failed to load content...</span>');
                });
            }, speed);
        };
        LightGallery.prototype.handleLgObjectLoad = function ($el, index, delay, speed, dummyImageLoaded) {
            var _this = this;
            setTimeout(function () {
                $el.addClass('lg-complete lg-complete_');
                if (!dummyImageLoaded) {
                    _this.LGel.trigger(lGEvents.slideItemLoad, {
                        index: index,
                        delay: delay || 0,
                    });
                }
            }, speed);
        };
        /**
         * @desc Check the given src is video
         * @param {String} src
         * @return {Object} video type
         * Ex:{ youtube  :  ["//www.youtube.com/watch?v=c0asJgSyxcY", "c0asJgSyxcY"] }
         *
         * @todo - this information can be moved to dynamicEl to avoid frequent calls
         */
        LightGallery.prototype.isVideo = function (src, index) {
            if (!src) {
                if (this.galleryItems[index].video) {
                    return {
                        html5: true,
                    };
                }
                else {
                    console.error('lightGallery :- data-src is not provided on slide item ' +
                        (index + 1) +
                        '. Please make sure the selector property is properly configured. More info - http://sachinchoolur.github.io/lightGallery/demos/html-markup.html');
                    return;
                }
            }
            var youtube = src.match(/\/\/(?:www\.)?youtu(?:\.be|be\.com|be-nocookie\.com)\/(?:watch\?v=|embed\/)?([a-z0-9\-\_\%]+)/i);
            var vimeo = src.match(/\/\/(?:www\.)?(?:player\.)?vimeo.com\/(?:video\/)?([0-9a-z\-_]+)/i);
            var wistia = src.match(/https?:\/\/(.+)?(wistia\.com|wi\.st)\/(medias|embed)\/([0-9a-z\-_]+)(.*)/);
            if (youtube) {
                return {
                    youtube: youtube,
                };
            }
            else if (vimeo) {
                return {
                    vimeo: vimeo,
                };
            }
            else if (wistia) {
                return {
                    wistia: wistia,
                };
            }
        };
        // Add video slideInfo
        LightGallery.prototype.addSlideVideoInfo = function (items) {
            var _this = this;
            items.forEach(function (element, index) {
                element.__slideVideoInfo = _this.isVideo(element.src, index);
            });
        };
        /**
         *  Load slide content into slide.
         *  This is used to load content into slides that is not visible too
         *  @param {Number} index - index of the slide.
         *  @param {Boolean} rec - if true call loadcontent() function again.
         */
        LightGallery.prototype.loadContent = function (index, rec) {
            var _this = this;
            var currentGalleryItem = this.galleryItems[index];
            var $currentSlide = $LG(this.getSlideItemId(index));
            var poster = currentGalleryItem.poster, srcset = currentGalleryItem.srcset, sizes = currentGalleryItem.sizes, sources = currentGalleryItem.sources;
            var src = currentGalleryItem.src;
            var video = currentGalleryItem.video;
            var _html5Video = video && typeof video === 'string' ? JSON.parse(video) : video;
            if (currentGalleryItem.responsive) {
                var srcDyItms = currentGalleryItem.responsive.split(',');
                src = utils.getResponsiveSrc(srcDyItms) || src;
            }
            var videoInfo = currentGalleryItem.__slideVideoInfo;
            var lgVideoStyle = '';
            var iframe = !!currentGalleryItem.iframe;
            if (!$currentSlide.hasClass('lg-loaded')) {
                if (videoInfo) {
                    var _a = this.mediaContainerPosition, top_2 = _a.top, bottom = _a.bottom;
                    var videoSize = utils.getSize(this.items[index], this.$lgContent, top_2 + bottom, videoInfo && this.settings.videoMaxSize);
                    lgVideoStyle = this.getVideoContStyle(videoSize);
                }
                if (iframe) {
                    var markup = utils.getIframeMarkup(src, this.settings.iframeWidth, this.settings.iframeHeight, currentGalleryItem.iframeTitle);
                    $currentSlide.prepend(markup);
                }
                else if (poster) {
                    var dummyImg = '';
                    var isFirstSlide_1 = !this.lGalleryOn;
                    var hasStartAnimation = !this.lGalleryOn &&
                        this.zoomFromOrigin &&
                        this.currentImageSize;
                    if (hasStartAnimation) {
                        dummyImg = this.getDummyImageContent($currentSlide, index, '');
                    }
                    var markup = utils.getVideoPosterMarkup(poster, dummyImg || '', lgVideoStyle, videoInfo);
                    $currentSlide.prepend(markup);
                    var delay_1 = (hasStartAnimation
                        ? this.settings.startAnimationDuration
                        : this.settings.backdropDuration) + 100;
                    setTimeout(function () {
                        _this.LGel.trigger(lGEvents.hasVideo, {
                            index: index,
                            src: src,
                            html5Video: _html5Video,
                            hasPoster: true,
                            isFirstSlide: isFirstSlide_1,
                        });
                    }, delay_1);
                }
                else if (videoInfo) {
                    var markup = "<div class=\"lg-video-cont \" style=\"" + lgVideoStyle + "\"></div>";
                    $currentSlide.prepend(markup);
                    this.LGel.trigger(lGEvents.hasVideo, {
                        index: index,
                        src: src,
                        html5Video: _html5Video,
                        hasPoster: false,
                    });
                }
                else {
                    this.setImgMarkup(src, $currentSlide, index);
                    if (srcset || sources) {
                        var $img = $currentSlide.find('.lg-object');
                        this.initPictureFill($img);
                    }
                }
                this.LGel.trigger(lGEvents.afterAppendSlide, { index: index });
                if (this.lGalleryOn &&
                    this.settings.appendSubHtmlTo !== '.lg-sub-html') {
                    this.addHtml(index);
                }
            }
            // For first time add some delay for displaying the start animation.
            var _speed = 0;
            // delay for adding complete class. it is 0 except first time.
            var delay = 0;
            if (!this.lGalleryOn) {
                if (this.zoomFromOrigin && this.currentImageSize) {
                    delay = this.settings.startAnimationDuration + 10;
                }
                else {
                    delay = this.settings.backdropDuration + 10;
                }
            }
            // Do not change the delay value because it is required for zoom plugin.
            // If gallery opened from direct url (hash) speed value should be 0
            if (delay && !$LG(document.body).hasClass('lg-from-hash')) {
                _speed = delay;
            }
            // Only for first slide
            if (!this.lGalleryOn && this.zoomFromOrigin && this.currentImageSize) {
                setTimeout(function () {
                    $currentSlide
                        .removeClass('lg-start-end-progress lg-start-progress')
                        .removeAttr('style');
                }, this.settings.startAnimationDuration + 100);
                if (!$currentSlide.hasClass('lg-loaded')) {
                    setTimeout(function () {
                        $currentSlide
                            .find('.lg-img-wrap')
                            .append(utils.getImgMarkup(index, src, '', srcset, sizes, currentGalleryItem.sources));
                        if (srcset || sources) {
                            var $img = $currentSlide.find('.lg-object');
                            _this.initPictureFill($img);
                        }
                        _this.onLgObjectLoad($currentSlide, index, delay, _speed, true);
                        var mediaObject = $currentSlide
                            .find('.lg-object')
                            .first();
                        if (utils.isImageLoaded(mediaObject.get())) {
                            _this.loadContentOnLoad(index, $currentSlide, _speed);
                        }
                        else {
                            mediaObject.on('load.lg error.lg', function () {
                                _this.loadContentOnLoad(index, $currentSlide, _speed);
                            });
                        }
                    }, this.settings.startAnimationDuration + 100);
                }
            }
            // SLide content has been added to dom
            $currentSlide.addClass('lg-loaded');
            this.onLgObjectLoad($currentSlide, index, delay, _speed, false);
            // @todo check load state for html5 videos
            if (videoInfo && videoInfo.html5 && !poster) {
                $currentSlide.addClass('lg-complete lg-complete_');
            }
            // When gallery is opened once content is loaded (second time) need to add lg-complete class for css styling
            if ((!this.zoomFromOrigin || !this.currentImageSize) &&
                $currentSlide.hasClass('lg-complete_') &&
                !this.lGalleryOn) {
                setTimeout(function () {
                    $currentSlide.addClass('lg-complete');
                }, this.settings.backdropDuration);
            }
            // Content loaded
            // Need to set lGalleryOn before calling preload function
            this.lGalleryOn = true;
            if (rec === true) {
                if (!$currentSlide.hasClass('lg-complete_')) {
                    $currentSlide
                        .find('.lg-object')
                        .first()
                        .on('load.lg error.lg', function () {
                        _this.preload(index);
                    });
                }
                else {
                    this.preload(index);
                }
            }
        };
        LightGallery.prototype.loadContentOnLoad = function (index, $currentSlide, speed) {
            var _this = this;
            setTimeout(function () {
                $currentSlide.find('.lg-dummy-img').remove();
                $currentSlide.removeClass('lg-first-slide');
                _this.isDummyImageRemoved = true;
                _this.preload(index);
            }, speed + 300);
        };
        LightGallery.prototype.getItemsToBeInsertedToDom = function (index, prevIndex, numberOfItems) {
            var _this = this;
            if (numberOfItems === void 0) { numberOfItems = 0; }
            var itemsToBeInsertedToDom = [];
            // Minimum 2 items should be there
            var possibleNumberOfItems = Math.max(numberOfItems, 3);
            possibleNumberOfItems = Math.min(possibleNumberOfItems, this.galleryItems.length);
            var prevIndexItem = "lg-item-" + this.lgId + "-" + prevIndex;
            if (this.galleryItems.length <= 3) {
                this.galleryItems.forEach(function (_element, index) {
                    itemsToBeInsertedToDom.push("lg-item-" + _this.lgId + "-" + index);
                });
                return itemsToBeInsertedToDom;
            }
            if (index < (this.galleryItems.length - 1) / 2) {
                for (var idx = index; idx > index - possibleNumberOfItems / 2 && idx >= 0; idx--) {
                    itemsToBeInsertedToDom.push("lg-item-" + this.lgId + "-" + idx);
                }
                var numberOfExistingItems = itemsToBeInsertedToDom.length;
                for (var idx = 0; idx < possibleNumberOfItems - numberOfExistingItems; idx++) {
                    itemsToBeInsertedToDom.push("lg-item-" + this.lgId + "-" + (index + idx + 1));
                }
            }
            else {
                for (var idx = index; idx <= this.galleryItems.length - 1 &&
                    idx < index + possibleNumberOfItems / 2; idx++) {
                    itemsToBeInsertedToDom.push("lg-item-" + this.lgId + "-" + idx);
                }
                var numberOfExistingItems = itemsToBeInsertedToDom.length;
                for (var idx = 0; idx < possibleNumberOfItems - numberOfExistingItems; idx++) {
                    itemsToBeInsertedToDom.push("lg-item-" + this.lgId + "-" + (index - idx - 1));
                }
            }
            if (this.settings.loop) {
                if (index === this.galleryItems.length - 1) {
                    itemsToBeInsertedToDom.push("lg-item-" + this.lgId + "-" + 0);
                }
                else if (index === 0) {
                    itemsToBeInsertedToDom.push("lg-item-" + this.lgId + "-" + (this.galleryItems.length - 1));
                }
            }
            if (itemsToBeInsertedToDom.indexOf(prevIndexItem) === -1) {
                itemsToBeInsertedToDom.push("lg-item-" + this.lgId + "-" + prevIndex);
            }
            return itemsToBeInsertedToDom;
        };
        LightGallery.prototype.organizeSlideItems = function (index, prevIndex) {
            var _this = this;
            var itemsToBeInsertedToDom = this.getItemsToBeInsertedToDom(index, prevIndex, this.settings.numberOfSlideItemsInDom);
            itemsToBeInsertedToDom.forEach(function (item) {
                if (_this.currentItemsInDom.indexOf(item) === -1) {
                    _this.$inner.append("<div id=\"" + item + "\" class=\"lg-item\"></div>");
                }
            });
            this.currentItemsInDom.forEach(function (item) {
                if (itemsToBeInsertedToDom.indexOf(item) === -1) {
                    $LG("#" + item).remove();
                }
            });
            return itemsToBeInsertedToDom;
        };
        /**
         * Get previous index of the slide
         */
        LightGallery.prototype.getPreviousSlideIndex = function () {
            var prevIndex = 0;
            try {
                var currentItemId = this.outer
                    .find('.lg-current')
                    .first()
                    .attr('id');
                prevIndex = parseInt(currentItemId.split('-')[3]) || 0;
            }
            catch (error) {
                prevIndex = 0;
            }
            return prevIndex;
        };
        LightGallery.prototype.setDownloadValue = function (index) {
            if (this.settings.download) {
                var currentGalleryItem = this.galleryItems[index];
                var src = currentGalleryItem.downloadUrl !== false &&
                    (currentGalleryItem.downloadUrl || currentGalleryItem.src);
                if (src && !currentGalleryItem.iframe) {
                    this.getElementById('lg-download').attr('href', src);
                }
            }
        };
        LightGallery.prototype.makeSlideAnimation = function (direction, currentSlideItem, previousSlideItem) {
            var _this = this;
            if (this.lGalleryOn) {
                previousSlideItem.addClass('lg-slide-progress');
            }
            setTimeout(function () {
                // remove all transitions
                _this.outer.addClass('lg-no-trans');
                _this.outer
                    .find('.lg-item')
                    .removeClass('lg-prev-slide lg-next-slide');
                if (direction === 'prev') {
                    //prevslide
                    currentSlideItem.addClass('lg-prev-slide');
                    previousSlideItem.addClass('lg-next-slide');
                }
                else {
                    // next slide
                    currentSlideItem.addClass('lg-next-slide');
                    previousSlideItem.addClass('lg-prev-slide');
                }
                // give 50 ms for browser to add/remove class
                setTimeout(function () {
                    _this.outer.find('.lg-item').removeClass('lg-current');
                    currentSlideItem.addClass('lg-current');
                    // reset all transitions
                    _this.outer.removeClass('lg-no-trans');
                }, 50);
            }, this.settings.slideDelay);
        };
        /**
         * Goto a specific slide.
         * @param {Number} index - index of the slide
         * @param {Boolean} fromTouch - true if slide function called via touch event or mouse drag
         * @param {Boolean} fromThumb - true if slide function called via thumbnail click
         * @param {String} direction - Direction of the slide(next/prev)
         * @category lGPublicMethods
         * @example
         *  const plugin = lightGallery();
         *  // to go to 3rd slide
         *  plugin.slide(2);
         *
         */
        LightGallery.prototype.slide = function (index, fromTouch, fromThumb, direction) {
            var _this = this;
            var prevIndex = this.getPreviousSlideIndex();
            this.currentItemsInDom = this.organizeSlideItems(index, prevIndex);
            // Prevent multiple call, Required for hsh plugin
            if (this.lGalleryOn && prevIndex === index) {
                return;
            }
            var numberOfGalleryItems = this.galleryItems.length;
            if (!this.lgBusy) {
                if (this.settings.counter) {
                    this.updateCurrentCounter(index);
                }
                var currentSlideItem = this.getSlideItem(index);
                var previousSlideItem_1 = this.getSlideItem(prevIndex);
                var currentGalleryItem = this.galleryItems[index];
                var videoInfo = currentGalleryItem.__slideVideoInfo;
                this.outer.attr('data-lg-slide-type', this.getSlideType(currentGalleryItem));
                this.setDownloadValue(index);
                if (videoInfo) {
                    var _a = this.mediaContainerPosition, top_3 = _a.top, bottom = _a.bottom;
                    var videoSize = utils.getSize(this.items[index], this.$lgContent, top_3 + bottom, videoInfo && this.settings.videoMaxSize);
                    this.resizeVideoSlide(index, videoSize);
                }
                this.LGel.trigger(lGEvents.beforeSlide, {
                    prevIndex: prevIndex,
                    index: index,
                    fromTouch: !!fromTouch,
                    fromThumb: !!fromThumb,
                });
                this.lgBusy = true;
                clearTimeout(this.hideBarTimeout);
                this.arrowDisable(index);
                if (!direction) {
                    if (index < prevIndex) {
                        direction = 'prev';
                    }
                    else if (index > prevIndex) {
                        direction = 'next';
                    }
                }
                if (!fromTouch) {
                    this.makeSlideAnimation(direction, currentSlideItem, previousSlideItem_1);
                }
                else {
                    this.outer
                        .find('.lg-item')
                        .removeClass('lg-prev-slide lg-current lg-next-slide');
                    var touchPrev = void 0;
                    var touchNext = void 0;
                    if (numberOfGalleryItems > 2) {
                        touchPrev = index - 1;
                        touchNext = index + 1;
                        if (index === 0 && prevIndex === numberOfGalleryItems - 1) {
                            // next slide
                            touchNext = 0;
                            touchPrev = numberOfGalleryItems - 1;
                        }
                        else if (index === numberOfGalleryItems - 1 &&
                            prevIndex === 0) {
                            // prev slide
                            touchNext = 0;
                            touchPrev = numberOfGalleryItems - 1;
                        }
                    }
                    else {
                        touchPrev = 0;
                        touchNext = 1;
                    }
                    if (direction === 'prev') {
                        this.getSlideItem(touchNext).addClass('lg-next-slide');
                    }
                    else {
                        this.getSlideItem(touchPrev).addClass('lg-prev-slide');
                    }
                    currentSlideItem.addClass('lg-current');
                }
                // Do not put load content in set timeout as it needs to load immediately when the gallery is opened
                if (!this.lGalleryOn) {
                    this.loadContent(index, true);
                }
                setTimeout(function () {
                    if (_this.lGalleryOn) {
                        _this.loadContent(index, true);
                    }
                    // Add title if this.settings.appendSubHtmlTo === lg-sub-html
                    if (_this.settings.appendSubHtmlTo === '.lg-sub-html') {
                        _this.addHtml(index);
                    }
                }, (this.lGalleryOn ? this.settings.speed + 50 : 50) + (fromTouch ? 0 : this.settings.slideDelay));
                setTimeout(function () {
                    _this.lgBusy = false;
                    previousSlideItem_1.removeClass('lg-slide-progress');
                    _this.LGel.trigger(lGEvents.afterSlide, {
                        prevIndex: prevIndex,
                        index: index,
                        fromTouch: fromTouch,
                        fromThumb: fromThumb,
                    });
                }, (this.lGalleryOn ? this.settings.speed + 100 : 100) + (fromTouch ? 0 : this.settings.slideDelay));
            }
            this.index = index;
        };
        LightGallery.prototype.updateCurrentCounter = function (index) {
            this.getElementById('lg-counter-current').html(index + 1 + '');
        };
        LightGallery.prototype.updateCounterTotal = function () {
            this.getElementById('lg-counter-all').html(this.galleryItems.length + '');
        };
        LightGallery.prototype.getSlideType = function (item) {
            if (item.__slideVideoInfo) {
                return 'video';
            }
            else if (item.iframe) {
                return 'iframe';
            }
            else {
                return 'image';
            }
        };
        LightGallery.prototype.touchMove = function (startCoords, endCoords) {
            var distanceX = endCoords.pageX - startCoords.pageX;
            var distanceY = endCoords.pageY - startCoords.pageY;
            var allowSwipe = false;
            if (this.swipeDirection) {
                allowSwipe = true;
            }
            else {
                if (Math.abs(distanceX) > 15) {
                    this.swipeDirection = 'horizontal';
                    allowSwipe = true;
                }
                else if (Math.abs(distanceY) > 15) {
                    this.swipeDirection = 'vertical';
                    allowSwipe = true;
                }
            }
            if (!allowSwipe) {
                return;
            }
            var $currentSlide = this.getSlideItem(this.index);
            if (this.swipeDirection === 'horizontal') {
                // reset opacity and transition duration
                this.outer.addClass('lg-dragging');
                // move current slide
                this.setTranslate($currentSlide, distanceX, 0);
                // move next and prev slide with current slide
                var width = $currentSlide.get().offsetWidth;
                var slideWidthAmount = (width * 15) / 100;
                var gutter = slideWidthAmount - Math.abs((distanceX * 10) / 100);
                this.setTranslate(this.outer.find('.lg-prev-slide').first(), -width + distanceX - gutter, 0);
                this.setTranslate(this.outer.find('.lg-next-slide').first(), width + distanceX + gutter, 0);
            }
            else if (this.swipeDirection === 'vertical') {
                if (this.settings.swipeToClose) {
                    this.$container.addClass('lg-dragging-vertical');
                    var opacity = 1 - Math.abs(distanceY) / window.innerHeight;
                    this.$backdrop.css('opacity', opacity);
                    var scale = 1 - Math.abs(distanceY) / (window.innerWidth * 2);
                    this.setTranslate($currentSlide, 0, distanceY, scale, scale);
                    if (Math.abs(distanceY) > 100) {
                        this.outer
                            .addClass('lg-hide-items')
                            .removeClass('lg-components-open');
                    }
                }
            }
        };
        LightGallery.prototype.touchEnd = function (endCoords, startCoords, event) {
            var _this = this;
            var distance;
            // keep slide animation for any mode while dragg/swipe
            if (this.settings.mode !== 'lg-slide') {
                this.outer.addClass('lg-slide');
            }
            // set transition duration
            setTimeout(function () {
                _this.$container.removeClass('lg-dragging-vertical');
                _this.outer
                    .removeClass('lg-dragging lg-hide-items')
                    .addClass('lg-components-open');
                var triggerClick = true;
                if (_this.swipeDirection === 'horizontal') {
                    distance = endCoords.pageX - startCoords.pageX;
                    var distanceAbs = Math.abs(endCoords.pageX - startCoords.pageX);
                    if (distance < 0 &&
                        distanceAbs > _this.settings.swipeThreshold) {
                        _this.goToNextSlide(true);
                        triggerClick = false;
                    }
                    else if (distance > 0 &&
                        distanceAbs > _this.settings.swipeThreshold) {
                        _this.goToPrevSlide(true);
                        triggerClick = false;
                    }
                }
                else if (_this.swipeDirection === 'vertical') {
                    distance = Math.abs(endCoords.pageY - startCoords.pageY);
                    if (_this.settings.closable &&
                        _this.settings.swipeToClose &&
                        distance > 100) {
                        _this.closeGallery();
                        return;
                    }
                    else {
                        _this.$backdrop.css('opacity', 1);
                    }
                }
                _this.outer.find('.lg-item').removeAttr('style');
                if (triggerClick &&
                    Math.abs(endCoords.pageX - startCoords.pageX) < 5) {
                    // Trigger click if distance is less than 5 pix
                    var target = $LG(event.target);
                    if (_this.isPosterElement(target)) {
                        _this.LGel.trigger(lGEvents.posterClick);
                    }
                }
                _this.swipeDirection = undefined;
            });
            // remove slide class once drag/swipe is completed if mode is not slide
            setTimeout(function () {
                if (!_this.outer.hasClass('lg-dragging') &&
                    _this.settings.mode !== 'lg-slide') {
                    _this.outer.removeClass('lg-slide');
                }
            }, this.settings.speed + 100);
        };
        LightGallery.prototype.enableSwipe = function () {
            var _this = this;
            var startCoords = {};
            var endCoords = {};
            var isMoved = false;
            var isSwiping = false;
            if (this.settings.enableSwipe) {
                this.$inner.on('touchstart.lg', function (e) {
                    e.preventDefault();
                    var $item = _this.getSlideItem(_this.index);
                    if (($LG(e.target).hasClass('lg-item') ||
                        $item.get().contains(e.target)) &&
                        !_this.outer.hasClass('lg-zoomed') &&
                        !_this.lgBusy &&
                        e.targetTouches.length === 1) {
                        isSwiping = true;
                        _this.touchAction = 'swipe';
                        _this.manageSwipeClass();
                        startCoords = {
                            pageX: e.targetTouches[0].pageX,
                            pageY: e.targetTouches[0].pageY,
                        };
                    }
                });
                this.$inner.on('touchmove.lg', function (e) {
                    e.preventDefault();
                    if (isSwiping &&
                        _this.touchAction === 'swipe' &&
                        e.targetTouches.length === 1) {
                        endCoords = {
                            pageX: e.targetTouches[0].pageX,
                            pageY: e.targetTouches[0].pageY,
                        };
                        _this.touchMove(startCoords, endCoords);
                        isMoved = true;
                    }
                });
                this.$inner.on('touchend.lg', function (event) {
                    if (_this.touchAction === 'swipe') {
                        if (isMoved) {
                            isMoved = false;
                            _this.touchEnd(endCoords, startCoords, event);
                        }
                        else if (isSwiping) {
                            var target = $LG(event.target);
                            if (_this.isPosterElement(target)) {
                                _this.LGel.trigger(lGEvents.posterClick);
                            }
                        }
                        _this.touchAction = undefined;
                        isSwiping = false;
                    }
                });
            }
        };
        LightGallery.prototype.enableDrag = function () {
            var _this = this;
            var startCoords = {};
            var endCoords = {};
            var isDraging = false;
            var isMoved = false;
            if (this.settings.enableDrag) {
                this.outer.on('mousedown.lg', function (e) {
                    var $item = _this.getSlideItem(_this.index);
                    if ($LG(e.target).hasClass('lg-item') ||
                        $item.get().contains(e.target)) {
                        if (!_this.outer.hasClass('lg-zoomed') && !_this.lgBusy) {
                            e.preventDefault();
                            if (!_this.lgBusy) {
                                _this.manageSwipeClass();
                                startCoords = {
                                    pageX: e.pageX,
                                    pageY: e.pageY,
                                };
                                isDraging = true;
                                // ** Fix for webkit cursor issue https://code.google.com/p/chromium/issues/detail?id=26723
                                _this.outer.get().scrollLeft += 1;
                                _this.outer.get().scrollLeft -= 1;
                                // *
                                _this.outer
                                    .removeClass('lg-grab')
                                    .addClass('lg-grabbing');
                                _this.LGel.trigger(lGEvents.dragStart);
                            }
                        }
                    }
                });
                $LG(window).on("mousemove.lg.global" + this.lgId, function (e) {
                    if (isDraging && _this.lgOpened) {
                        isMoved = true;
                        endCoords = {
                            pageX: e.pageX,
                            pageY: e.pageY,
                        };
                        _this.touchMove(startCoords, endCoords);
                        _this.LGel.trigger(lGEvents.dragMove);
                    }
                });
                $LG(window).on("mouseup.lg.global" + this.lgId, function (event) {
                    if (!_this.lgOpened) {
                        return;
                    }
                    var target = $LG(event.target);
                    if (isMoved) {
                        isMoved = false;
                        _this.touchEnd(endCoords, startCoords, event);
                        _this.LGel.trigger(lGEvents.dragEnd);
                    }
                    else if (_this.isPosterElement(target)) {
                        _this.LGel.trigger(lGEvents.posterClick);
                    }
                    // Prevent execution on click
                    if (isDraging) {
                        isDraging = false;
                        _this.outer.removeClass('lg-grabbing').addClass('lg-grab');
                    }
                });
            }
        };
        LightGallery.prototype.manageSwipeClass = function () {
            var _touchNext = this.index + 1;
            var _touchPrev = this.index - 1;
            if (this.settings.loop && this.galleryItems.length > 2) {
                if (this.index === 0) {
                    _touchPrev = this.galleryItems.length - 1;
                }
                else if (this.index === this.galleryItems.length - 1) {
                    _touchNext = 0;
                }
            }
            this.outer.find('.lg-item').removeClass('lg-next-slide lg-prev-slide');
            if (_touchPrev > -1) {
                this.getSlideItem(_touchPrev).addClass('lg-prev-slide');
            }
            this.getSlideItem(_touchNext).addClass('lg-next-slide');
        };
        /**
         * Go to next slide
         * @param {Boolean} fromTouch - true if slide function called via touch event
         * @category lGPublicMethods
         * @example
         *  const plugin = lightGallery();
         *  plugin.goToNextSlide();
         * @see <a href="/demos/methods/">Demo</a>
         */
        LightGallery.prototype.goToNextSlide = function (fromTouch) {
            var _this = this;
            var _loop = this.settings.loop;
            if (fromTouch && this.galleryItems.length < 3) {
                _loop = false;
            }
            if (!this.lgBusy) {
                if (this.index + 1 < this.galleryItems.length) {
                    this.index++;
                    this.LGel.trigger(lGEvents.beforeNextSlide, {
                        index: this.index,
                    });
                    this.slide(this.index, !!fromTouch, false, 'next');
                }
                else {
                    if (_loop) {
                        this.index = 0;
                        this.LGel.trigger(lGEvents.beforeNextSlide, {
                            index: this.index,
                        });
                        this.slide(this.index, !!fromTouch, false, 'next');
                    }
                    else if (this.settings.slideEndAnimation && !fromTouch) {
                        this.outer.addClass('lg-right-end');
                        setTimeout(function () {
                            _this.outer.removeClass('lg-right-end');
                        }, 400);
                    }
                }
            }
        };
        /**
         * Go to previous slides
         * @param {Boolean} fromTouch - true if slide function called via touch event
         * @category lGPublicMethods
         * @example
         *  const plugin = lightGallery({});
         *  plugin.goToPrevSlide();
         * @see <a href="/demos/methods/">Demo</a>
         *
         */
        LightGallery.prototype.goToPrevSlide = function (fromTouch) {
            var _this = this;
            var _loop = this.settings.loop;
            if (fromTouch && this.galleryItems.length < 3) {
                _loop = false;
            }
            if (!this.lgBusy) {
                if (this.index > 0) {
                    this.index--;
                    this.LGel.trigger(lGEvents.beforePrevSlide, {
                        index: this.index,
                        fromTouch: fromTouch,
                    });
                    this.slide(this.index, !!fromTouch, false, 'prev');
                }
                else {
                    if (_loop) {
                        this.index = this.galleryItems.length - 1;
                        this.LGel.trigger(lGEvents.beforePrevSlide, {
                            index: this.index,
                            fromTouch: fromTouch,
                        });
                        this.slide(this.index, !!fromTouch, false, 'prev');
                    }
                    else if (this.settings.slideEndAnimation && !fromTouch) {
                        this.outer.addClass('lg-left-end');
                        setTimeout(function () {
                            _this.outer.removeClass('lg-left-end');
                        }, 400);
                    }
                }
            }
        };
        LightGallery.prototype.keyPress = function () {
            var _this = this;
            $LG(window).on("keydown.lg.global" + this.lgId, function (e) {
                if (_this.lgOpened &&
                    _this.settings.escKey === true &&
                    e.keyCode === 27) {
                    e.preventDefault();
                    if (_this.settings.allowMediaOverlap &&
                        _this.outer.hasClass('lg-can-toggle') &&
                        _this.outer.hasClass('lg-components-open')) {
                        _this.outer.removeClass('lg-components-open');
                    }
                    else {
                        _this.closeGallery();
                    }
                }
                if (_this.lgOpened && _this.galleryItems.length > 1) {
                    if (e.keyCode === 37) {
                        e.preventDefault();
                        _this.goToPrevSlide();
                    }
                    if (e.keyCode === 39) {
                        e.preventDefault();
                        _this.goToNextSlide();
                    }
                }
            });
        };
        LightGallery.prototype.arrow = function () {
            var _this = this;
            this.getElementById('lg-prev').on('click.lg', function () {
                _this.goToPrevSlide();
            });
            this.getElementById('lg-next').on('click.lg', function () {
                _this.goToNextSlide();
            });
        };
        LightGallery.prototype.arrowDisable = function (index) {
            // Disable arrows if settings.hideControlOnEnd is true
            if (!this.settings.loop && this.settings.hideControlOnEnd) {
                var $prev = this.getElementById('lg-prev');
                var $next = this.getElementById('lg-next');
                if (index + 1 < this.galleryItems.length) {
                    $prev.removeAttr('disabled').removeClass('disabled');
                }
                else {
                    $prev.attr('disabled', 'disabled').addClass('disabled');
                }
                if (index > 0) {
                    $next.removeAttr('disabled').removeClass('disabled');
                }
                else {
                    $next.attr('disabled', 'disabled').addClass('disabled');
                }
            }
        };
        /**
         * Get index of the slide from custom slideName. Has to be a public method. Used in hash plugin
         * @param {String} hash
         * @returns {Number} Index of the slide.
         */
        LightGallery.prototype.getIndexFromUrl = function (hash) {
            if (hash === void 0) { hash = window.location.hash; }
            var slideName = hash.split('&slide=')[1];
            var _idx = 0;
            if (this.settings.customSlideName) {
                for (var index = 0; index < this.galleryItems.length; index++) {
                    var dynamicEl = this.galleryItems[index];
                    if (dynamicEl.slideName === slideName) {
                        _idx = index;
                        break;
                    }
                }
            }
            else {
                _idx = parseInt(slideName, 10);
            }
            return isNaN(_idx) ? 0 : _idx;
        };
        LightGallery.prototype.setTranslate = function ($el, xValue, yValue, scaleX, scaleY) {
            if (scaleX === void 0) { scaleX = 1; }
            if (scaleY === void 0) { scaleY = 1; }
            $el.css('transform', 'translate3d(' +
                xValue +
                'px, ' +
                yValue +
                'px, 0px) scale3d(' +
                scaleX +
                ', ' +
                scaleY +
                ', 1)');
        };
        LightGallery.prototype.mousewheel = function () {
            var _this = this;
            this.outer.on('mousewheel.lg', function (e) {
                if (!e.deltaY) {
                    return;
                }
                if (e.deltaY > 0) {
                    _this.goToPrevSlide();
                }
                else {
                    _this.goToNextSlide();
                }
                e.preventDefault();
            });
        };
        LightGallery.prototype.isSlideElement = function (target) {
            return (target.hasClass('lg-outer') ||
                target.hasClass('lg-item') ||
                target.hasClass('lg-img-wrap'));
        };
        LightGallery.prototype.isPosterElement = function (target) {
            var playButton = this.getSlideItem(this.index)
                .find('.lg-video-play-button')
                .get();
            return (target.hasClass('lg-video-poster') ||
                target.hasClass('lg-video-play-button') ||
                (playButton && playButton.contains(target.get())));
        };
        /**
         * Maximize minimize inline gallery.
         * @category lGPublicMethods
         */
        LightGallery.prototype.toggleMaximize = function () {
            var _this = this;
            this.getElementById('lg-maximize').on('click.lg', function () {
                _this.$container.toggleClass('lg-inline');
                _this.refreshOnResize();
            });
        };
        LightGallery.prototype.manageCloseGallery = function () {
            var _this = this;
            if (!this.settings.closable)
                return;
            var mousedown = false;
            this.getElementById('lg-close').on('click.lg', function () {
                _this.closeGallery();
            });
            if (this.settings.closeOnTap) {
                // If you drag the slide and release outside gallery gets close on chrome
                // for preventing this check mousedown and mouseup happened on .lg-item or lg-outer
                this.outer.on('mousedown.lg', function (e) {
                    var target = $LG(e.target);
                    if (_this.isSlideElement(target)) {
                        mousedown = true;
                    }
                    else {
                        mousedown = false;
                    }
                });
                this.outer.on('mousemove.lg', function () {
                    mousedown = false;
                });
                this.outer.on('mouseup.lg', function (e) {
                    var target = $LG(e.target);
                    if (_this.isSlideElement(target) && mousedown) {
                        if (!_this.outer.hasClass('lg-dragging')) {
                            _this.closeGallery();
                        }
                    }
                });
            }
        };
        /**
         * Close lightGallery if it is opened.
         *
         * @description If closable is false in the settings, you need to pass true via closeGallery method to force close gallery
         * @return returns the estimated time to close gallery completely including the close animation duration
         * @category lGPublicMethods
         * @example
         *  const plugin = lightGallery();
         *  plugin.closeGallery();
         *
         */
        LightGallery.prototype.closeGallery = function (force) {
            var _this = this;
            if (!this.lgOpened || (!this.settings.closable && !force)) {
                return 0;
            }
            this.LGel.trigger(lGEvents.beforeClose);
            $LG(window).scrollTop(this.prevScrollTop);
            var currentItem = this.items[this.index];
            var transform;
            if (this.zoomFromOrigin && currentItem) {
                var _a = this.mediaContainerPosition, top_4 = _a.top, bottom = _a.bottom;
                var imageSize = utils.getSize(currentItem, this.$lgContent, top_4 + bottom, this.galleryItems[this.index].__slideVideoInfo &&
                    this.settings.videoMaxSize);
                transform = utils.getTransform(currentItem, this.$lgContent, top_4, bottom, imageSize);
            }
            if (this.zoomFromOrigin && transform) {
                this.outer.addClass('lg-closing lg-zoom-from-image');
                this.getSlideItem(this.index)
                    .addClass('lg-start-end-progress')
                    .css('transition-duration', this.settings.startAnimationDuration + 'ms')
                    .css('transform', transform);
            }
            else {
                this.outer.addClass('lg-hide-items');
                // lg-zoom-from-image is used for setting the opacity to 1 if zoomFromOrigin is true
                // If the closing item doesn't have the lg-size attribute, remove this class to avoid the closing css conflicts
                this.outer.removeClass('lg-zoom-from-image');
            }
            // Unbind all events added by lightGallery
            // @todo
            //this.$el.off('.lg.tm');
            this.destroyModules();
            this.lGalleryOn = false;
            this.isDummyImageRemoved = false;
            this.zoomFromOrigin = this.settings.zoomFromOrigin;
            clearTimeout(this.hideBarTimeout);
            this.hideBarTimeout = false;
            $LG(document.body).removeClass('lg-on lg-from-hash');
            this.outer.removeClass('lg-visible lg-components-open');
            // Resetting opacity to 0 isd required as  vertical swipe to close function adds inline opacity.
            this.$backdrop.removeClass('in').css('opacity', 0);
            var removeTimeout = this.zoomFromOrigin && transform
                ? Math.max(this.settings.startAnimationDuration, this.settings.backdropDuration)
                : this.settings.backdropDuration;
            this.$container.removeClass('lg-show-in');
            // Once the closign animation is completed and gallery is invisible
            setTimeout(function () {
                if (_this.zoomFromOrigin && transform) {
                    _this.outer.removeClass('lg-zoom-from-image');
                }
                _this.$container.removeClass('lg-show');
                // Need to remove inline opacity as it is used in the stylesheet as well
                _this.$backdrop
                    .removeAttr('style')
                    .css('transition-duration', _this.settings.backdropDuration + 'ms');
                _this.outer.removeClass("lg-closing " + _this.settings.startClass);
                _this.getSlideItem(_this.index).removeClass('lg-start-end-progress');
                _this.$inner.empty();
                if (_this.lgOpened) {
                    _this.LGel.trigger(lGEvents.afterClose, {
                        instance: _this,
                    });
                }
                _this.LGel.get().focus();
                _this.lgOpened = false;
            }, removeTimeout + 100);
            return removeTimeout + 100;
        };
        LightGallery.prototype.destroyModules = function (destroy) {
            this.plugins.forEach(function (module) {
                try {
                    if (destroy) {
                        module.destroy();
                    }
                    else {
                        module.closeGallery && module.closeGallery();
                    }
                }
                catch (err) {
                    console.warn("lightGallery:- make sure lightGallery module is properly destroyed");
                }
            });
            for (var key in this.plugins) {
                if (this.plugins[key]) {
                    try {
                        if (destroy) {
                            this.plugins[key].destroy();
                        }
                        else {
                            this.plugins[key].closeGallery &&
                                this.plugins[key].closeGallery();
                        }
                    }
                    catch (err) {
                        console.warn("lightGallery:- make sure lightGallery " + key + " module is properly destroyed");
                    }
                }
            }
        };
        /**
         * Destroy lightGallery.
         * Destroy lightGallery and its plugin instances completely
         *
         * @description This method also calls CloseGallery function internally
         * @category lGPublicMethods
         * @example
         *  const plugin = lightGallery();
         *  plugin.destroy();
         *
         */
        LightGallery.prototype.destroy = function () {
            var _this = this;
            var closeTimeout = this.closeGallery(true);
            setTimeout(function () {
                _this.destroyModules(true);
                if (!_this.settings.dynamic) {
                    for (var index = 0; index < _this.items.length; index++) {
                        var element = _this.items[index];
                        var $element = $LG(element);
                        $element.off("click.lgcustom-item-" + $element.attr('data-lg-id'));
                    }
                }
                $LG(window).off(".lg.global" + _this.lgId);
                _this.LGel.off('.lg');
                _this.$container.remove();
            }, closeTimeout);
        };
        return LightGallery;
    }());

    function lightGallery(el, options) {
        if (!el) {
            return;
        }
        try {
            return new LightGallery(el, options);
        }
        catch (err) {
            console.error('lightGallery has not initiated properly', err);
        }
    }

    return lightGallery;

})));
//# sourceMappingURL=lightgallery.umd.js.map

/*!
 * lightgallery | 2.0.0-beta.3 | May 4th 2021
 * http://sachinchoolur.github.io/lightGallery/
 * Copyright (c) 2020 Sachin Neravath;
 * @license GPLv3
 */

(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define(factory) :
    (global.lgZoom = factory());
}(this, (function () { 'use strict';

    /*! *****************************************************************************
    Copyright (c) Microsoft Corporation.

    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
    REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
    INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
    LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
    OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
    PERFORMANCE OF THIS SOFTWARE.
    ***************************************************************************** */

    var __assign = function() {
        __assign = Object.assign || function __assign(t) {
            for (var s, i = 1, n = arguments.length; i < n; i++) {
                s = arguments[i];
                for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
            }
            return t;
        };
        return __assign.apply(this, arguments);
    };

    var zoomSettings = {
        scale: 1,
        zoom: true,
        actualSize: true,
        showZoomInOutIcons: false,
        actualSizeIcons: {
            zoomIn: 'lg-zoom-in',
            zoomOut: 'lg-zoom-out',
        },
        enableZoomAfter: 300,
    };

    /**
     * List of lightGallery events
     * All events should be documented here
     * Below interfaces are used to build the website documentations
     * */
    var lGEvents = {
        afterAppendSlide: 'lgAfterAppendSlide',
        init: 'lgInit',
        hasVideo: 'lgHasVideo',
        containerResize: 'lgContainerResize',
        updateSlides: 'lgUpdateSlides',
        afterAppendSubHtml: 'lgAfterAppendSubHtml',
        beforeOpen: 'lgBeforeOpen',
        afterOpen: 'lgAfterOpen',
        slideItemLoad: 'lgSlideItemLoad',
        beforeSlide: 'lgBeforeSlide',
        afterSlide: 'lgAfterSlide',
        posterClick: 'lgPosterClick',
        dragStart: 'lgDragStart',
        dragMove: 'lgDragMove',
        dragEnd: 'lgDragEnd',
        beforeNextSlide: 'lgBeforeNextSlide',
        beforePrevSlide: 'lgBeforePrevSlide',
        beforeClose: 'lgBeforeClose',
        afterClose: 'lgAfterClose',
    };

    var Zoom = /** @class */ (function () {
        function Zoom(instance, $LG) {
            // get lightGallery core plugin instance
            this.core = instance;
            this.$LG = $LG;
            this.settings = __assign(__assign({}, zoomSettings), this.core.settings);
            if (this.settings.zoom) {
                this.init();
                // Store the zoomable timeout value just to clear it while closing
                this.zoomableTimeout = false;
                this.positionChanged = false;
                // Set the initial value center
                this.pageX = this.core.outer.width() / 2;
                this.pageY =
                    this.core.outer.height() / 2 + this.$LG(window).scrollTop();
                this.scale = 1;
            }
            return this;
        }
        // Append Zoom controls. Actual size, Zoom-in, Zoom-out
        Zoom.prototype.buildTemplates = function () {
            var zoomIcons = this.settings.showZoomInOutIcons
                ? "<button id=\"" + this.core.getIdName('lg-zoom-in') + "\" type=\"button\" class=\"lg-zoom-in lg-icon\"></button><button id=\"" + this.core.getIdName('lg-zoom-out') + "\" type=\"button\" class=\"lg-zoom-out lg-icon\"></button>"
                : '';
            if (this.settings.actualSize) {
                zoomIcons += "<button id=\"" + this.core.getIdName('lg-actual-size') + "\" type=\"button\" class=\"" + this.settings.actualSizeIcons.zoomIn + " lg-icon\"></button>";
            }
            this.core.outer.addClass('lg-use-transition-for-zoom');
            this.core.$toolbar.first().append(zoomIcons);
        };
        /**
         * @desc Enable zoom option only once the image is completely loaded
         * If zoomFromOrigin is true, Zoom is enabled once the dummy image has been inserted
         *
         * Zoom styles are defined under lg-zoomable CSS class.
         */
        Zoom.prototype.enableZoom = function (event) {
            var _this = this;
            // delay will be 0 except first time
            var _speed = this.settings.enableZoomAfter + event.detail.delay;
            // set _speed value 0 if gallery opened from direct url and if it is first slide
            if (this.$LG('body').first().hasClass('lg-from-hash') &&
                event.detail.delay) {
                // will execute only once
                _speed = 0;
            }
            else {
                // Remove lg-from-hash to enable starting animation.
                this.$LG('body').first().removeClass('lg-from-hash');
            }
            this.zoomableTimeout = setTimeout(function () {
                _this.core.getSlideItem(event.detail.index).addClass('lg-zoomable');
            }, _speed + 30);
        };
        Zoom.prototype.enableZoomOnSlideItemLoad = function () {
            // Add zoomable class
            this.core.LGel.on(lGEvents.slideItemLoad + ".zoom", this.enableZoom.bind(this));
        };
        Zoom.prototype.getModifier = function (rotateValue, axis, el) {
            var originalRotate = rotateValue;
            rotateValue = Math.abs(rotateValue);
            var transformValues = this.getCurrentTransform(el);
            if (!transformValues) {
                return 1;
            }
            var modifier = 1;
            if (axis === 'X') {
                var flipHorizontalValue = Math.sign(parseFloat(transformValues[0]));
                if (rotateValue === 0 || rotateValue === 180) {
                    modifier = 1;
                }
                else if (rotateValue === 90) {
                    if ((originalRotate === -90 && flipHorizontalValue === 1) ||
                        (originalRotate === 90 && flipHorizontalValue === -1)) {
                        modifier = -1;
                    }
                    else {
                        modifier = 1;
                    }
                }
                modifier = modifier * flipHorizontalValue;
            }
            else {
                var flipVerticalValue = Math.sign(parseFloat(transformValues[3]));
                if (rotateValue === 0 || rotateValue === 180) {
                    modifier = 1;
                }
                else if (rotateValue === 90) {
                    var sinX = parseFloat(transformValues[1]);
                    var sinMinusX = parseFloat(transformValues[2]);
                    modifier = Math.sign(sinX * sinMinusX * originalRotate * flipVerticalValue);
                }
                modifier = modifier * flipVerticalValue;
            }
            return modifier;
        };
        Zoom.prototype.getImageSize = function ($image, rotateValue, axis) {
            var imageSizes = {
                y: 'offsetHeight',
                x: 'offsetWidth',
            };
            if (rotateValue === 90) {
                // Swap axis
                if (axis === 'x') {
                    axis = 'y';
                }
                else {
                    axis = 'x';
                }
            }
            return $image[imageSizes[axis]];
        };
        Zoom.prototype.getDragCords = function (e, rotateValue) {
            if (rotateValue === 90) {
                return {
                    x: e.pageY,
                    y: e.pageX,
                };
            }
            else {
                return {
                    x: e.pageX,
                    y: e.pageY,
                };
            }
        };
        Zoom.prototype.getSwipeCords = function (e, rotateValue) {
            var x = e.targetTouches[0].pageX;
            var y = e.targetTouches[0].pageY;
            if (rotateValue === 90) {
                return {
                    x: y,
                    y: x,
                };
            }
            else {
                return {
                    x: x,
                    y: y,
                };
            }
        };
        Zoom.prototype.getDragAllowedAxises = function ($image, rotateValue) {
            var $lg = this.core.$lgContent.get();
            var scale = parseFloat($image.attr('data-scale')) || 1;
            var imgEl = $image.get();
            var allowY = this.getImageSize(imgEl, rotateValue, 'y') * scale >
                $lg.clientHeight;
            var allowX = this.getImageSize(imgEl, rotateValue, 'x') * scale >
                $lg.clientWidth;
            if (rotateValue === 90) {
                return {
                    allowX: allowY,
                    allowY: allowX,
                };
            }
            else {
                return {
                    allowX: allowX,
                    allowY: allowY,
                };
            }
        };
        /**
         *
         * @param {Element} el
         * @return matrix(cos(X), sin(X), -sin(X), cos(X), 0, 0);
         * Get the current transform value
         */
        Zoom.prototype.getCurrentTransform = function (el) {
            if (!el) {
                return;
            }
            var st = window.getComputedStyle(el, null);
            var tm = st.getPropertyValue('-webkit-transform') ||
                st.getPropertyValue('-moz-transform') ||
                st.getPropertyValue('-ms-transform') ||
                st.getPropertyValue('-o-transform') ||
                st.getPropertyValue('transform') ||
                'none';
            if (tm !== 'none') {
                return tm.split('(')[1].split(')')[0].split(',');
            }
            return;
        };
        Zoom.prototype.getCurrentRotation = function (el) {
            if (!el) {
                return 0;
            }
            var values = this.getCurrentTransform(el);
            if (values) {
                return Math.round(Math.atan2(parseFloat(values[1]), parseFloat(values[0])) *
                    (180 / Math.PI));
                // If you want rotate in 360
                //return (angle < 0 ? angle + 360 : angle);
            }
            return 0;
        };
        /**
         * @desc Image zoom
         * Translate the wrap and scale the image to get better user experience
         *
         * @param {String} scale - Zoom decrement/increment value
         */
        Zoom.prototype.zoomImage = function (scale) {
            var $image = this.core
                .getSlideItem(this.core.index)
                .find('.lg-image')
                .first();
            var imageNode = $image.get();
            if (!imageNode)
                return;
            var containerRect = this.core.outer.get().getBoundingClientRect();
            // Find offset manually to avoid issue after zoom
            var offsetX = (containerRect.width - imageNode.offsetWidth) / 2 +
                containerRect.left;
            var offsetY = (containerRect.height - imageNode.offsetHeight) / 2 +
                this.$LG(window).scrollTop() +
                containerRect.top;
            var originalX;
            var originalY;
            if (scale === 1) {
                this.positionChanged = false;
            }
            if (this.positionChanged) {
                originalX =
                    parseFloat($image.parent().attr('data-x')) /
                        (parseFloat($image.attr('data-scale')) - 1);
                originalY =
                    parseFloat($image.parent().attr('data-y')) /
                        (parseFloat($image.attr('data-scale')) - 1);
                this.pageX = originalX + offsetX;
                this.pageY = originalY + offsetY;
                this.positionChanged = false;
            }
            var _x = this.pageX - offsetX;
            var _y = this.pageY - offsetY;
            var x = (scale - 1) * _x;
            var y = (scale - 1) * _y;
            this.setZoomStyles({
                x: x,
                y: y,
                scale: scale,
            });
        };
        /**
         * @desc apply scale3d to image and translate to image wrap
         * @param {style} X,Y and scale
         */
        Zoom.prototype.setZoomStyles = function (style) {
            var $image = this.core
                .getSlideItem(this.core.index)
                .find('.lg-image')
                .first();
            var $dummyImage = this.core.outer
                .find('.lg-current .lg-dummy-img')
                .first();
            var $imageWrap = $image.parent();
            $image
                .attr('data-scale', style.scale + '')
                .css('transform', 'scale3d(' + style.scale + ', ' + style.scale + ', 1)');
            $dummyImage.css('transform', 'scale3d(' + style.scale + ', ' + style.scale + ', 1)');
            var transform = 'translate3d(-' + style.x + 'px, -' + style.y + 'px, 0)';
            $imageWrap.css('transform', transform);
            $imageWrap.attr('data-x', style.x).attr('data-y', style.y);
        };
        /**
         * @param index - Index of the current slide
         * @param event - event will be available only if the function is called on clicking/taping the imags
         */
        Zoom.prototype.setActualSize = function (index, event) {
            var _this = this;
            var currentItem = this.core.galleryItems[this.core.index];
            // Allow zoom only on image
            if (!currentItem.src) {
                return;
            }
            var scale = this.getCurrentImageActualSizeScale();
            if (this.core.outer.hasClass('lg-zoomed')) {
                this.scale = 1;
            }
            else {
                this.scale = this.getScale(scale);
            }
            this.setPageCords(event);
            this.beginZoom(this.scale);
            this.zoomImage(this.scale);
            setTimeout(function () {
                _this.core.outer.removeClass('lg-grabbing').addClass('lg-grab');
            }, 10);
        };
        Zoom.prototype.getNaturalWidth = function (index) {
            var $image = this.core.getSlideItem(index).find('.lg-image').first();
            var naturalWidth = this.core.galleryItems[index].width;
            return naturalWidth
                ? parseFloat(naturalWidth)
                : $image.get().naturalWidth;
        };
        Zoom.prototype.getActualSizeScale = function (naturalWidth, width) {
            var _scale;
            var scale;
            if (naturalWidth > width) {
                _scale = naturalWidth / width;
                scale = _scale || 2;
            }
            else {
                scale = 1;
            }
            return scale;
        };
        Zoom.prototype.getCurrentImageActualSizeScale = function () {
            var $image = this.core
                .getSlideItem(this.core.index)
                .find('.lg-image')
                .first();
            var width = $image.get().offsetWidth;
            var naturalWidth = this.getNaturalWidth(this.core.index) || width;
            return this.getActualSizeScale(naturalWidth, width);
        };
        Zoom.prototype.getPageCords = function (event) {
            var cords = {};
            if (event) {
                cords.x = event.pageX || event.targetTouches[0].pageX;
                cords.y = event.pageY || event.targetTouches[0].pageY;
            }
            else {
                var containerRect = this.core.outer.get().getBoundingClientRect();
                cords.x = containerRect.width / 2 + containerRect.left;
                cords.y =
                    containerRect.height / 2 +
                        this.$LG(window).scrollTop() +
                        containerRect.top;
            }
            return cords;
        };
        Zoom.prototype.setPageCords = function (event) {
            var pageCords = this.getPageCords(event);
            this.pageX = pageCords.x;
            this.pageY = pageCords.y;
        };
        // If true, zoomed - in else zoomed out
        Zoom.prototype.beginZoom = function (scale) {
            this.core.outer.removeClass('lg-zoom-drag-transition lg-zoom-dragging');
            if (scale > 1) {
                this.core.outer.addClass('lg-zoomed');
                var $actualSize = this.core.getElementById('lg-actual-size');
                $actualSize
                    .removeClass(this.settings.actualSizeIcons.zoomIn)
                    .addClass(this.settings.actualSizeIcons.zoomOut);
            }
            else {
                this.resetZoom();
            }
            return scale > 1;
        };
        Zoom.prototype.getScale = function (scale) {
            var actualSizeScale = this.getCurrentImageActualSizeScale();
            if (scale < 1) {
                scale = 1;
            }
            else if (scale > actualSizeScale) {
                scale = actualSizeScale;
            }
            return scale;
        };
        Zoom.prototype.init = function () {
            var _this = this;
            this.buildTemplates();
            this.enableZoomOnSlideItemLoad();
            var tapped = null;
            this.core.outer.on('dblclick.lg', function (event) {
                if (!_this.$LG(event.target).hasClass('lg-image')) {
                    return;
                }
                _this.setActualSize(_this.core.index, event);
            });
            this.core.outer.on('touchstart.lg', function (event) {
                var $target = _this.$LG(event.target);
                if (event.targetTouches.length === 1 &&
                    $target.hasClass('lg-image')) {
                    if (!tapped) {
                        tapped = setTimeout(function () {
                            tapped = null;
                        }, 300);
                    }
                    else {
                        clearTimeout(tapped);
                        tapped = null;
                        _this.setActualSize(_this.core.index, event);
                    }
                    event.preventDefault();
                }
            });
            // Update zoom on resize and orientationchange
            this.core.LGel.on(lGEvents.containerResize + ".zoom", function () {
                if (!_this.core.lgOpened)
                    return;
                _this.setPageCords();
                _this.zoomImage(_this.scale);
            });
            this.core.getElementById('lg-zoom-out').on('click.lg', function () {
                if (_this.core.outer.find('.lg-current .lg-image').get()) {
                    _this.scale -= _this.settings.scale;
                    _this.scale = _this.getScale(_this.scale);
                    _this.beginZoom(_this.scale);
                    _this.zoomImage(_this.scale);
                }
            });
            this.core.getElementById('lg-zoom-in').on('click.lg', function () {
                _this.zoomIn();
            });
            this.core.getElementById('lg-actual-size').on('click.lg', function () {
                _this.setActualSize(_this.core.index);
            });
            this.core.LGel.on(lGEvents.beforeOpen + ".zoom", function () {
                _this.core.outer.find('.lg-item').removeClass('lg-zoomable');
            });
            // Reset zoom on slide change
            this.core.LGel.on(lGEvents.afterSlide + ".zoom", function (event) {
                var prevIndex = event.detail.prevIndex;
                _this.scale = 1;
                _this.resetZoom(prevIndex);
            });
            // Drag option after zoom
            this.zoomDrag();
            this.pinchZoom();
            this.zoomSwipe();
        };
        Zoom.prototype.zoomIn = function (scale) {
            var currentItem = this.core.galleryItems[this.core.index];
            // Allow zoom only on image
            if (!currentItem.src) {
                return;
            }
            if (scale) {
                this.scale = scale;
            }
            else {
                this.scale += this.settings.scale;
            }
            this.scale = this.getScale(this.scale);
            this.beginZoom(this.scale);
            this.zoomImage(this.scale);
        };
        // Reset zoom effect
        Zoom.prototype.resetZoom = function (index) {
            this.core.outer.removeClass('lg-zoomed lg-zoom-drag-transition');
            var $actualSize = this.core.getElementById('lg-actual-size');
            var $item = this.core.getSlideItem(index !== undefined ? index : this.core.index);
            $actualSize
                .removeClass(this.settings.actualSizeIcons.zoomOut)
                .addClass(this.settings.actualSizeIcons.zoomIn);
            $item.find('.lg-img-wrap').first().removeAttr('style data-x data-y');
            $item.find('.lg-image').first().removeAttr('style data-scale');
            // Reset pagx pagy values to center
            this.setPageCords();
        };
        Zoom.prototype.getTouchDistance = function (e) {
            return Math.sqrt((e.targetTouches[0].pageX - e.targetTouches[1].pageX) *
                (e.targetTouches[0].pageX - e.targetTouches[1].pageX) +
                (e.targetTouches[0].pageY - e.targetTouches[1].pageY) *
                    (e.targetTouches[0].pageY - e.targetTouches[1].pageY));
        };
        Zoom.prototype.pinchZoom = function () {
            var _this = this;
            var startDist = 0;
            var pinchStarted = false;
            var initScale = 1;
            var $item = this.core.getSlideItem(this.core.index);
            this.core.$inner.on('touchstart.lg', function (e) {
                $item = _this.core.getSlideItem(_this.core.index);
                e.preventDefault();
                if (e.targetTouches.length === 2 &&
                    (_this.$LG(e.target).hasClass('lg-item') ||
                        $item.get().contains(e.target))) {
                    initScale = _this.scale || 1;
                    _this.core.outer.removeClass('lg-zoom-drag-transition lg-zoom-dragging');
                    _this.core.touchAction = 'pinch';
                    startDist = _this.getTouchDistance(e);
                }
            });
            this.core.$inner.on('touchmove.lg', function (e) {
                e.preventDefault();
                if (e.targetTouches.length === 2 &&
                    _this.core.touchAction === 'pinch' &&
                    (_this.$LG(e.target).hasClass('lg-item') ||
                        $item.get().contains(e.target))) {
                    var endDist = _this.getTouchDistance(e);
                    var distance = startDist - endDist;
                    if (!pinchStarted && Math.abs(distance) > 5) {
                        pinchStarted = true;
                    }
                    if (pinchStarted) {
                        _this.scale = Math.max(1, initScale + -distance * 0.008);
                        _this.zoomImage(_this.scale);
                    }
                }
            });
            this.core.$inner.on('touchend.lg', function (e) {
                if (_this.core.touchAction === 'pinch' &&
                    (_this.$LG(e.target).hasClass('lg-item') ||
                        $item.get().contains(e.target))) {
                    pinchStarted = false;
                    startDist = 0;
                    if (_this.scale <= 1) {
                        _this.resetZoom();
                    }
                    else {
                        _this.scale = _this.getScale(_this.scale);
                        _this.zoomImage(_this.scale);
                        _this.core.outer.addClass('lg-zoomed');
                    }
                    _this.core.touchAction = undefined;
                }
            });
        };
        Zoom.prototype.touchendZoom = function (startCoords, endCoords, allowX, allowY, touchDuration, rotateValue) {
            var rotateEl = this.core
                .getSlideItem(this.core.index)
                .find('.lg-img-rotate')
                .first()
                .get();
            var distanceXnew = endCoords.x - startCoords.x;
            var distanceYnew = endCoords.y - startCoords.y;
            var speedX = Math.abs(distanceXnew) / touchDuration + 1;
            var speedY = Math.abs(distanceYnew) / touchDuration + 1;
            if (speedX > 2) {
                speedX += 1;
            }
            if (speedY > 2) {
                speedY += 1;
            }
            distanceXnew = distanceXnew * speedX;
            distanceYnew = distanceYnew * speedY;
            var _LGel = this.core
                .getSlideItem(this.core.index)
                .find('.lg-img-wrap')
                .first();
            var $image = this.core
                .getSlideItem(this.core.index)
                .find('.lg-object')
                .first();
            var dataX = parseFloat(_LGel.attr('data-x')) || 0;
            var dataY = parseFloat(_LGel.attr('data-y')) || 0;
            var distance = {};
            distance.x =
                -Math.abs(dataX) +
                    distanceXnew * this.getModifier(rotateValue, 'X', rotateEl);
            distance.y =
                -Math.abs(dataY) +
                    distanceYnew * this.getModifier(rotateValue, 'Y', rotateEl);
            var possibleSwipeCords = this.getPossibleSwipeDragCords($image, rotateValue);
            if (Math.abs(distanceXnew) > 15 || Math.abs(distanceYnew) > 15) {
                if (allowY) {
                    if (distance.y <= -possibleSwipeCords.maxY) {
                        distance.y = -possibleSwipeCords.maxY;
                    }
                    else if (distance.y >= -possibleSwipeCords.minY) {
                        distance.y = -possibleSwipeCords.minY;
                    }
                }
                if (allowX) {
                    if (distance.x <= -possibleSwipeCords.maxX) {
                        distance.x = -possibleSwipeCords.maxX;
                    }
                    else if (distance.x >= -possibleSwipeCords.minX) {
                        distance.x = -possibleSwipeCords.minX;
                    }
                }
                if (allowY) {
                    _LGel.attr('data-y', Math.abs(distance.y));
                }
                else {
                    var dataY_1 = parseFloat(_LGel.attr('data-y')) || 0;
                    distance.y = -Math.abs(dataY_1);
                }
                if (allowX) {
                    _LGel.attr('data-x', Math.abs(distance.x));
                }
                else {
                    var dataX_1 = parseFloat(_LGel.attr('data-x')) || 0;
                    distance.x = -Math.abs(dataX_1);
                }
                this.setZoomSwipeStyles(_LGel, distance);
                this.positionChanged = true;
            }
        };
        Zoom.prototype.getZoomSwipeCords = function (startCoords, endCoords, allowX, allowY, possibleSwipeCords, dataY, dataX, rotateValue, rotateEl) {
            var distance = {};
            if (allowY) {
                distance.y =
                    -Math.abs(dataY) +
                        (endCoords.y - startCoords.y) *
                            this.getModifier(rotateValue, 'Y', rotateEl);
                if (distance.y <= -possibleSwipeCords.maxY) {
                    var diffMaxY = -possibleSwipeCords.maxY - distance.y;
                    distance.y = -possibleSwipeCords.maxY - diffMaxY / 6;
                }
                else if (distance.y >= -possibleSwipeCords.minY) {
                    var diffMinY = distance.y - -possibleSwipeCords.minY;
                    distance.y = -possibleSwipeCords.minY + diffMinY / 6;
                }
            }
            else {
                distance.y = -Math.abs(dataY);
            }
            if (allowX) {
                distance.x =
                    -Math.abs(dataX) +
                        (endCoords.x - startCoords.x) *
                            this.getModifier(rotateValue, 'X', rotateEl);
                if (distance.x <= -possibleSwipeCords.maxX) {
                    var diffMaxX = -possibleSwipeCords.maxX - distance.x;
                    distance.x = -possibleSwipeCords.maxX - diffMaxX / 6;
                }
                else if (distance.x >= -possibleSwipeCords.minX) {
                    var diffMinX = distance.x - -possibleSwipeCords.minX;
                    distance.x = -possibleSwipeCords.minX + diffMinX / 6;
                }
            }
            else {
                distance.x = -Math.abs(dataX);
            }
            return distance;
        };
        Zoom.prototype.getPossibleSwipeDragCords = function ($image, rotateValue) {
            var $cont = this.core.$lgContent;
            var contHeight = $cont.height();
            var contWidth = $cont.width();
            var imageYSize = this.getImageSize($image.get(), rotateValue, 'y');
            var imageXSize = this.getImageSize($image.get(), rotateValue, 'x');
            var dataY = parseFloat($image.attr('data-scale')) || 1;
            var elDataScale = Math.abs(dataY);
            var minY = (contHeight - imageYSize) / 2;
            var maxY = Math.abs(imageYSize * elDataScale - contHeight + minY);
            var minX = (contWidth - imageXSize) / 2;
            var maxX = Math.abs(imageXSize * elDataScale - contWidth + minX);
            if (rotateValue === 90) {
                return {
                    minY: minX,
                    maxY: maxX,
                    minX: minY,
                    maxX: maxY,
                };
            }
            else {
                return {
                    minY: minY,
                    maxY: maxY,
                    minX: minX,
                    maxX: maxX,
                };
            }
        };
        Zoom.prototype.setZoomSwipeStyles = function (LGel, distance) {
            LGel.css('transform', 'translate3d(' + distance.x + 'px, ' + distance.y + 'px, 0)');
        };
        Zoom.prototype.zoomSwipe = function () {
            var _this = this;
            var startCoords = {};
            var endCoords = {};
            var isMoved = false;
            // Allow x direction drag
            var allowX = false;
            // Allow Y direction drag
            var allowY = false;
            var startTime = new Date();
            var endTime = new Date();
            var dataX = 0;
            var dataY = 0;
            var possibleSwipeCords;
            var _LGel;
            var rotateEl = null;
            var rotateValue = 0;
            var $item = this.core.getSlideItem(this.core.index);
            this.core.$inner.on('touchstart.lg', function (e) {
                e.preventDefault();
                var currentItem = _this.core.galleryItems[_this.core.index];
                // Allow zoom only on image
                if (!currentItem.src) {
                    return;
                }
                $item = _this.core.getSlideItem(_this.core.index);
                if ((_this.$LG(e.target).hasClass('lg-item') ||
                    $item.get().contains(e.target)) &&
                    e.targetTouches.length === 1 &&
                    _this.core.outer.hasClass('lg-zoomed')) {
                    startTime = new Date();
                    _this.core.touchAction = 'zoomSwipe';
                    var $image = _this.core
                        .getSlideItem(_this.core.index)
                        .find('.lg-object')
                        .first();
                    _LGel = _this.core
                        .getSlideItem(_this.core.index)
                        .find('.lg-img-wrap')
                        .first();
                    rotateEl = _this.core
                        .getSlideItem(_this.core.index)
                        .find('.lg-img-rotate')
                        .first()
                        .get();
                    rotateValue = _this.getCurrentRotation(rotateEl);
                    var dragAllowedAxises = _this.getDragAllowedAxises($image, Math.abs(rotateValue));
                    allowY = dragAllowedAxises.allowY;
                    allowX = dragAllowedAxises.allowX;
                    if (allowX || allowY) {
                        startCoords = _this.getSwipeCords(e, Math.abs(rotateValue));
                    }
                    dataY = parseFloat(_LGel.attr('data-y'));
                    dataX = parseFloat(_LGel.attr('data-x'));
                    possibleSwipeCords = _this.getPossibleSwipeDragCords($image, rotateValue);
                    // reset opacity and transition duration
                    _this.core.outer.addClass('lg-zoom-dragging lg-zoom-drag-transition');
                }
            });
            this.core.$inner.on('touchmove.lg', function (e) {
                e.preventDefault();
                if (e.targetTouches.length === 1 &&
                    _this.core.touchAction === 'zoomSwipe' &&
                    (_this.$LG(e.target).hasClass('lg-item') ||
                        $item.get().contains(e.target))) {
                    _this.core.touchAction = 'zoomSwipe';
                    endCoords = _this.getSwipeCords(e, Math.abs(rotateValue));
                    var distance = _this.getZoomSwipeCords(startCoords, endCoords, allowX, allowY, possibleSwipeCords, dataY, dataX, rotateValue, rotateEl);
                    if (Math.abs(endCoords.x - startCoords.x) > 15 ||
                        Math.abs(endCoords.y - startCoords.y) > 15) {
                        isMoved = true;
                        _this.setZoomSwipeStyles(_LGel, distance);
                    }
                }
            });
            this.core.$inner.on('touchend.lg', function (e) {
                if (_this.core.touchAction === 'zoomSwipe' &&
                    (_this.$LG(e.target).hasClass('lg-item') ||
                        $item.get().contains(e.target))) {
                    _this.core.touchAction = undefined;
                    _this.core.outer.removeClass('lg-zoom-dragging');
                    if (!isMoved) {
                        return;
                    }
                    isMoved = false;
                    endTime = new Date();
                    var touchDuration = endTime.valueOf() - startTime.valueOf();
                    _this.touchendZoom(startCoords, endCoords, allowX, allowY, touchDuration, rotateValue);
                }
            });
        };
        Zoom.prototype.zoomDrag = function () {
            var _this = this;
            var startCoords = {};
            var endCoords = {};
            var isDragging = false;
            var isMoved = false;
            var rotateEl = null;
            var rotateValue = 0;
            // Allow x direction drag
            var allowX = false;
            // Allow Y direction drag
            var allowY = false;
            var startTime;
            var endTime;
            var possibleSwipeCords;
            var dataY;
            var dataX;
            var _LGel;
            this.core.outer.on('mousedown.lg.zoom', function (e) {
                var currentItem = _this.core.galleryItems[_this.core.index];
                // Allow zoom only on image
                if (!currentItem.src) {
                    return;
                }
                var $item = _this.core.getSlideItem(_this.core.index);
                if (_this.$LG(e.target).hasClass('lg-item') ||
                    $item.get().contains(e.target)) {
                    startTime = new Date();
                    // execute only on .lg-object
                    var $image = _this.core
                        .getSlideItem(_this.core.index)
                        .find('.lg-object')
                        .first();
                    _LGel = _this.core
                        .getSlideItem(_this.core.index)
                        .find('.lg-img-wrap')
                        .first();
                    rotateEl = _this.core
                        .getSlideItem(_this.core.index)
                        .find('.lg-img-rotate')
                        .get();
                    rotateValue = _this.getCurrentRotation(rotateEl);
                    var dragAllowedAxises = _this.getDragAllowedAxises($image, Math.abs(rotateValue));
                    allowY = dragAllowedAxises.allowY;
                    allowX = dragAllowedAxises.allowX;
                    if (_this.core.outer.hasClass('lg-zoomed')) {
                        if (_this.$LG(e.target).hasClass('lg-object') &&
                            (allowX || allowY)) {
                            e.preventDefault();
                            startCoords = _this.getDragCords(e, Math.abs(rotateValue));
                            possibleSwipeCords = _this.getPossibleSwipeDragCords($image, rotateValue);
                            isDragging = true;
                            dataY = parseFloat(_LGel.attr('data-y'));
                            dataX = parseFloat(_LGel.attr('data-x'));
                            // ** Fix for webkit cursor issue https://code.google.com/p/chromium/issues/detail?id=26723
                            _this.core.outer.get().scrollLeft += 1;
                            _this.core.outer.get().scrollLeft -= 1;
                            _this.core.outer
                                .removeClass('lg-grab')
                                .addClass('lg-grabbing lg-zoom-drag-transition lg-zoom-dragging');
                            // reset opacity and transition duration
                        }
                    }
                }
            });
            this.$LG(window).on("mousemove.lg.zoom.global" + this.core.lgId, function (e) {
                if (isDragging) {
                    isMoved = true;
                    endCoords = _this.getDragCords(e, Math.abs(rotateValue));
                    var distance = _this.getZoomSwipeCords(startCoords, endCoords, allowX, allowY, possibleSwipeCords, dataY, dataX, rotateValue, rotateEl);
                    _this.setZoomSwipeStyles(_LGel, distance);
                }
            });
            this.$LG(window).on("mouseup.lg.zoom.global" + this.core.lgId, function (e) {
                if (isDragging) {
                    endTime = new Date();
                    isDragging = false;
                    _this.core.outer.removeClass('lg-zoom-dragging');
                    // Fix for chrome mouse move on click
                    if (isMoved &&
                        (startCoords.x !== endCoords.x ||
                            startCoords.y !== endCoords.y)) {
                        endCoords = _this.getDragCords(e, Math.abs(rotateValue));
                        var touchDuration = endTime.valueOf() - startTime.valueOf();
                        _this.touchendZoom(startCoords, endCoords, allowX, allowY, touchDuration, rotateValue);
                    }
                    isMoved = false;
                }
                _this.core.outer.removeClass('lg-grabbing').addClass('lg-grab');
            });
        };
        Zoom.prototype.closeGallery = function () {
            this.resetZoom();
        };
        Zoom.prototype.destroy = function () {
            // Unbind all events added by lightGallery zoom plugin
            this.$LG(window).off(".lg.zoom.global" + this.core.lgId);
            this.core.LGel.off('.lg.zoom');
            this.core.LGel.off('.zoom');
            clearTimeout(this.zoomableTimeout);
            this.zoomableTimeout = false;
        };
        return Zoom;
    }());

    return Zoom;

})));
//# sourceMappingURL=lg-zoom.umd.js.map

/*!
 * lightgallery | 2.0.0-beta.3 | May 4th 2021
 * http://sachinchoolur.github.io/lightGallery/
 * Copyright (c) 2020 Sachin Neravath;
 * @license GPLv3
 */

(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define(factory) :
    (global.lgThumbnail = factory());
}(this, (function () { 'use strict';

    /*! *****************************************************************************
    Copyright (c) Microsoft Corporation.

    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted.

    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
    REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
    INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
    LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
    OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
    PERFORMANCE OF THIS SOFTWARE.
    ***************************************************************************** */

    var __assign = function() {
        __assign = Object.assign || function __assign(t) {
            for (var s, i = 1, n = arguments.length; i < n; i++) {
                s = arguments[i];
                for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
            }
            return t;
        };
        return __assign.apply(this, arguments);
    };

    var thumbnailsSettings = {
        thumbnail: true,
        animateThumb: true,
        currentPagerPosition: 'middle',
        alignThumbnails: 'middle',
        thumbWidth: 100,
        thumbHeight: '80px',
        thumbMargin: 5,
        appendThumbnailsTo: '.lg-components',
        toggleThumb: false,
        enableThumbDrag: true,
        enableThumbSwipe: true,
        swipeThreshold: 10,
        loadYouTubeThumbnail: true,
        youTubeThumbSize: 1,
    };

    /**
     * List of lightGallery events
     * All events should be documented here
     * Below interfaces are used to build the website documentations
     * */
    var lGEvents = {
        afterAppendSlide: 'lgAfterAppendSlide',
        init: 'lgInit',
        hasVideo: 'lgHasVideo',
        containerResize: 'lgContainerResize',
        updateSlides: 'lgUpdateSlides',
        afterAppendSubHtml: 'lgAfterAppendSubHtml',
        beforeOpen: 'lgBeforeOpen',
        afterOpen: 'lgAfterOpen',
        slideItemLoad: 'lgSlideItemLoad',
        beforeSlide: 'lgBeforeSlide',
        afterSlide: 'lgAfterSlide',
        posterClick: 'lgPosterClick',
        dragStart: 'lgDragStart',
        dragMove: 'lgDragMove',
        dragEnd: 'lgDragEnd',
        beforeNextSlide: 'lgBeforeNextSlide',
        beforePrevSlide: 'lgBeforePrevSlide',
        beforeClose: 'lgBeforeClose',
        afterClose: 'lgAfterClose',
    };

    var Thumbnail = /** @class */ (function () {
        function Thumbnail(instance, $LG) {
            this.thumbOuterWidth = 0;
            this.thumbTotalWidth = 0;
            this.translateX = 0;
            this.thumbClickable = false;
            // get lightGallery core plugin instance
            this.core = instance;
            this.$LG = $LG;
            // extend module default settings with lightGallery core settings
            this.settings = __assign(__assign({}, thumbnailsSettings), this.core.settings);
            this.init();
            return this;
        }
        Thumbnail.prototype.init = function () {
            this.thumbOuterWidth = 0;
            this.thumbTotalWidth =
                this.core.galleryItems.length *
                    (this.settings.thumbWidth + this.settings.thumbMargin);
            // Thumbnail animation value
            this.translateX = 0;
            this.setAnimateThumbStyles();
            if (!this.core.settings.allowMediaOverlap) {
                this.settings.toggleThumb = false;
            }
            if (this.settings.thumbnail && this.core.galleryItems.length > 1) {
                this.build();
                if (this.settings.animateThumb) {
                    if (this.settings.enableThumbDrag) {
                        this.enableThumbDrag();
                    }
                    if (this.settings.enableThumbSwipe) {
                        this.enableThumbSwipe();
                    }
                    this.thumbClickable = false;
                }
                else {
                    this.thumbClickable = true;
                }
                this.toggleThumbBar();
                this.thumbKeyPress();
            }
        };
        Thumbnail.prototype.build = function () {
            var _this = this;
            this.setThumbMarkup();
            this.manageActiveClassOnSlideChange();
            this.$lgThumb.first().on('click.lg touchend.lg', function (e) {
                var $target = _this.$LG(e.target);
                if (!$target.hasAttribute('data-lg-item-id')) {
                    return;
                }
                setTimeout(function () {
                    // In IE9 and bellow touch does not support
                    // Go to slide if browser does not support css transitions
                    if (_this.thumbClickable && !_this.core.lgBusy) {
                        var index = parseInt($target.attr('data-lg-item-id'));
                        _this.core.slide(index, false, true, false);
                    }
                }, 50);
            });
            this.core.LGel.on(lGEvents.beforeSlide + ".thumb", function (event) {
                var index = event.detail.index;
                _this.animateThumb(index);
            });
            this.core.LGel.on(lGEvents.beforeOpen + ".thumb", function () {
                _this.thumbOuterWidth = _this.core.outer.get().offsetWidth;
            });
            this.core.LGel.on(lGEvents.updateSlides + ".thumb", function () {
                _this.rebuildThumbnails();
            });
            this.core.LGel.on(lGEvents.containerResize + ".thumb", function () {
                if (!_this.core.lgOpened)
                    return;
                setTimeout(function () {
                    _this.thumbOuterWidth = _this.core.outer.get().offsetWidth;
                    _this.animateThumb(_this.core.index);
                    _this.thumbOuterWidth = _this.core.outer.get().offsetWidth;
                }, 50);
            });
        };
        Thumbnail.prototype.setThumbMarkup = function () {
            var thumbOuterClassNames = 'lg-thumb-outer ';
            if (this.settings.alignThumbnails) {
                thumbOuterClassNames += "lg-thumb-align-" + this.settings.alignThumbnails;
            }
            var html = "<div class=\"" + thumbOuterClassNames + "\">\n        <div class=\"lg-thumb lg-group\">\n        </div>\n        </div>";
            this.core.outer.addClass('lg-has-thumb');
            if (this.settings.appendThumbnailsTo === '.lg-components') {
                this.core.$lgComponents.append(html);
            }
            else {
                this.core.outer.append(html);
            }
            this.$thumbOuter = this.core.outer.find('.lg-thumb-outer').first();
            this.$lgThumb = this.core.outer.find('.lg-thumb').first();
            if (this.settings.animateThumb) {
                this.core.outer
                    .find('.lg-thumb')
                    .css('transition-duration', this.core.settings.speed + 'ms')
                    .css('width', this.thumbTotalWidth + 'px')
                    .css('position', 'relative');
            }
            this.setThumbItemHtml(this.core.galleryItems);
        };
        Thumbnail.prototype.enableThumbDrag = function () {
            var _this = this;
            var thumbDragUtils = {
                cords: {
                    startX: 0,
                    endX: 0,
                },
                isMoved: false,
                newTranslateX: 0,
                startTime: new Date(),
                endTime: new Date(),
                touchMoveTime: 0,
            };
            var isDragging = false;
            this.$thumbOuter.addClass('lg-grab');
            this.core.outer
                .find('.lg-thumb')
                .first()
                .on('mousedown.lg.thumb', function (e) {
                if (_this.thumbTotalWidth > _this.thumbOuterWidth) {
                    // execute only on .lg-object
                    e.preventDefault();
                    thumbDragUtils.cords.startX = e.pageX;
                    thumbDragUtils.startTime = new Date();
                    _this.thumbClickable = false;
                    isDragging = true;
                    // ** Fix for webkit cursor issue https://code.google.com/p/chromium/issues/detail?id=26723
                    _this.core.outer.get().scrollLeft += 1;
                    _this.core.outer.get().scrollLeft -= 1;
                    // *
                    _this.$thumbOuter
                        .removeClass('lg-grab')
                        .addClass('lg-grabbing');
                }
            });
            this.$LG(window).on("mousemove.lg.thumb.global" + this.core.lgId, function (e) {
                if (!_this.core.lgOpened)
                    return;
                if (isDragging) {
                    thumbDragUtils.cords.endX = e.pageX;
                    thumbDragUtils = _this.onThumbTouchMove(thumbDragUtils);
                }
            });
            this.$LG(window).on("mouseup.lg.thumb.global" + this.core.lgId, function () {
                if (!_this.core.lgOpened)
                    return;
                if (thumbDragUtils.isMoved) {
                    thumbDragUtils = _this.onThumbTouchEnd(thumbDragUtils);
                }
                else {
                    _this.thumbClickable = true;
                }
                if (isDragging) {
                    isDragging = false;
                    _this.$thumbOuter.removeClass('lg-grabbing').addClass('lg-grab');
                }
            });
        };
        Thumbnail.prototype.enableThumbSwipe = function () {
            var _this = this;
            var thumbDragUtils = {
                cords: {
                    startX: 0,
                    endX: 0,
                },
                isMoved: false,
                newTranslateX: 0,
                startTime: new Date(),
                endTime: new Date(),
                touchMoveTime: 0,
            };
            this.$lgThumb.on('touchstart.lg', function (e) {
                if (_this.thumbTotalWidth > _this.thumbOuterWidth) {
                    e.preventDefault();
                    thumbDragUtils.cords.startX = e.targetTouches[0].pageX;
                    _this.thumbClickable = false;
                    thumbDragUtils.startTime = new Date();
                }
            });
            this.$lgThumb.on('touchmove.lg', function (e) {
                if (_this.thumbTotalWidth > _this.thumbOuterWidth) {
                    e.preventDefault();
                    thumbDragUtils.cords.endX = e.targetTouches[0].pageX;
                    thumbDragUtils = _this.onThumbTouchMove(thumbDragUtils);
                }
            });
            this.$lgThumb.on('touchend.lg', function () {
                if (thumbDragUtils.isMoved) {
                    thumbDragUtils = _this.onThumbTouchEnd(thumbDragUtils);
                }
                else {
                    _this.thumbClickable = true;
                }
            });
        };
        // Rebuild thumbnails
        Thumbnail.prototype.rebuildThumbnails = function () {
            var _this = this;
            // Remove transitions
            this.$thumbOuter.addClass('lg-rebuilding-thumbnails');
            setTimeout(function () {
                _this.thumbTotalWidth =
                    _this.core.galleryItems.length *
                        (_this.settings.thumbWidth + _this.settings.thumbMargin);
                _this.$lgThumb.css('width', _this.thumbTotalWidth + 'px');
                _this.$lgThumb.empty();
                _this.setThumbItemHtml(_this.core.galleryItems);
                _this.animateThumb(_this.core.index);
            }, 50);
            setTimeout(function () {
                _this.$thumbOuter.removeClass('lg-rebuilding-thumbnails');
            }, 200);
        };
        // @ts-check
        Thumbnail.prototype.setTranslate = function (value) {
            this.$lgThumb.css('transform', 'translate3d(-' + value + 'px, 0px, 0px)');
        };
        Thumbnail.prototype.getPossibleTransformX = function (left) {
            if (left > this.thumbTotalWidth - this.thumbOuterWidth) {
                left = this.thumbTotalWidth - this.thumbOuterWidth;
            }
            if (left < 0) {
                left = 0;
            }
            return left;
        };
        Thumbnail.prototype.animateThumb = function (index) {
            this.$lgThumb.css('transition-duration', this.core.settings.speed + 'ms');
            if (this.settings.animateThumb) {
                var position = 0;
                switch (this.settings.currentPagerPosition) {
                    case 'left':
                        position = 0;
                        break;
                    case 'middle':
                        position =
                            this.thumbOuterWidth / 2 - this.settings.thumbWidth / 2;
                        break;
                    case 'right':
                        position = this.thumbOuterWidth - this.settings.thumbWidth;
                }
                this.translateX =
                    (this.settings.thumbWidth + this.settings.thumbMargin) * index -
                        1 -
                        position;
                if (this.translateX > this.thumbTotalWidth - this.thumbOuterWidth) {
                    this.translateX = this.thumbTotalWidth - this.thumbOuterWidth;
                }
                if (this.translateX < 0) {
                    this.translateX = 0;
                }
                this.setTranslate(this.translateX);
            }
        };
        Thumbnail.prototype.onThumbTouchMove = function (thumbDragUtils) {
            thumbDragUtils.newTranslateX = this.translateX;
            thumbDragUtils.isMoved = true;
            thumbDragUtils.touchMoveTime = new Date().valueOf();
            thumbDragUtils.newTranslateX -=
                thumbDragUtils.cords.endX - thumbDragUtils.cords.startX;
            thumbDragUtils.newTranslateX = this.getPossibleTransformX(thumbDragUtils.newTranslateX);
            // move current slide
            this.setTranslate(thumbDragUtils.newTranslateX);
            this.$thumbOuter.addClass('lg-dragging');
            return thumbDragUtils;
        };
        Thumbnail.prototype.onThumbTouchEnd = function (thumbDragUtils) {
            thumbDragUtils.isMoved = false;
            thumbDragUtils.endTime = new Date();
            this.$thumbOuter.removeClass('lg-dragging');
            var touchDuration = thumbDragUtils.endTime.valueOf() -
                thumbDragUtils.startTime.valueOf();
            var distanceXnew = thumbDragUtils.cords.endX - thumbDragUtils.cords.startX;
            var speedX = Math.abs(distanceXnew) / touchDuration;
            // Some magical numbers
            // Can be improved
            if (speedX > 0.15 &&
                thumbDragUtils.endTime.valueOf() - thumbDragUtils.touchMoveTime < 30) {
                speedX += 1;
                if (speedX > 2) {
                    speedX += 1;
                }
                speedX =
                    speedX +
                        speedX * (Math.abs(distanceXnew) / this.thumbOuterWidth);
                this.$lgThumb.css('transition-duration', Math.min(speedX - 1, 2) + 'settings');
                distanceXnew = distanceXnew * speedX;
                this.translateX = this.getPossibleTransformX(this.translateX - distanceXnew);
                this.setTranslate(this.translateX);
            }
            else {
                this.translateX = thumbDragUtils.newTranslateX;
            }
            if (Math.abs(thumbDragUtils.cords.endX - thumbDragUtils.cords.startX) <
                this.settings.swipeThreshold) {
                this.thumbClickable = true;
            }
            return thumbDragUtils;
        };
        Thumbnail.prototype.getThumbHtml = function (thumb, index) {
            var slideVideoInfo = this.core.galleryItems[index].__slideVideoInfo || {};
            var thumbImg;
            if (slideVideoInfo.youtube) {
                if (this.settings.loadYouTubeThumbnail) {
                    thumbImg =
                        '//img.youtube.com/vi/' +
                            slideVideoInfo.youtube[1] +
                            '/' +
                            this.settings.youTubeThumbSize +
                            '.jpg';
                }
                else {
                    thumbImg = thumb;
                }
            }
            else {
                thumbImg = thumb;
            }
            return "<div data-lg-item-id=\"" + index + "\" class=\"lg-thumb-item " + (index === this.core.index ? ' active' : '') + "\" \n        style=\"width:" + this.settings.thumbWidth + "px; height: " + this.settings.thumbHeight + ";\n            margin-right: " + this.settings.thumbMargin + "px;\">\n            <img data-lg-item-id=\"" + index + "\" src=\"" + thumbImg + "\" />\n        </div>";
        };
        Thumbnail.prototype.getThumbItemHtml = function (items) {
            var thumbList = '';
            for (var i = 0; i < items.length; i++) {
                thumbList += this.getThumbHtml(items[i].thumb, i);
            }
            return thumbList;
        };
        Thumbnail.prototype.setThumbItemHtml = function (items) {
            var thumbList = this.getThumbItemHtml(items);
            this.$lgThumb.html(thumbList);
        };
        Thumbnail.prototype.setAnimateThumbStyles = function () {
            if (this.settings.animateThumb) {
                this.core.outer.addClass('lg-animate-thumb');
            }
        };
        // Manage thumbnail active calss
        Thumbnail.prototype.manageActiveClassOnSlideChange = function () {
            var _this = this;
            // manage active class for thumbnail
            this.core.LGel.on(lGEvents.beforeSlide + ".thumb", function (event) {
                var $thumb = _this.core.outer.find('.lg-thumb-item');
                var index = event.detail.index;
                $thumb.removeClass('active');
                $thumb.eq(index).addClass('active');
            });
        };
        // Toggle thumbnail bar
        Thumbnail.prototype.toggleThumbBar = function () {
            var _this = this;
            if (this.settings.toggleThumb) {
                this.core.outer.addClass('lg-can-toggle');
                this.core.$toolbar.append('<button type="button" aria-label="Toggle thumbnails" class="lg-toggle-thumb lg-icon"></button>');
                this.core.outer
                    .find('.lg-toggle-thumb')
                    .first()
                    .on('click.lg', function () {
                    _this.core.outer.toggleClass('lg-components-open');
                });
            }
        };
        Thumbnail.prototype.thumbKeyPress = function () {
            var _this = this;
            this.$LG(window).on("keydown.lg.thumb.global" + this.core.lgId, function (e) {
                if (!_this.core.lgOpened || !_this.settings.toggleThumb)
                    return;
                if (e.keyCode === 38) {
                    e.preventDefault();
                    _this.core.outer.addClass('lg-components-open');
                }
                else if (e.keyCode === 40) {
                    e.preventDefault();
                    _this.core.outer.removeClass('lg-components-open');
                }
            });
        };
        Thumbnail.prototype.destroy = function () {
            if (this.settings.thumbnail && this.core.galleryItems.length > 1) {
                this.$LG(window).off(".lg.thumb.global" + this.core.lgId);
                this.core.LGel.off('.lg.thumb');
                this.core.LGel.off('.thumb');
                this.$thumbOuter.remove();
                this.core.outer.removeClass('lg-has-thumb');
            }
        };
        return Thumbnail;
    }());

    return Thumbnail;

})));
//# sourceMappingURL=lg-thumbnail.umd.js.map

