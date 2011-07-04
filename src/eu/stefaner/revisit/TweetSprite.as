/*     Copyright 2010, Moritz Stefaner   Licensed under the Apache License, Version 2.0 (the "License");   you may not use this file except in compliance with the License.   You may obtain a copy of the License at       http://www.apache.org/licenses/LICENSE-2.0   Unless required by applicable law or agreed to in writing, software   distributed under the License is distributed on an "AS IS" BASIS,   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   See the License for the specific language governing permissions and   limitations under the License.    */package eu.stefaner.revisit {	import flare.animate.Transitioner;	import flare.util.Maths;	import flare.vis.axis.Axis;	import flare.vis.data.NodeSprite;	import com.swfjunkie.tweetr.utils.TweetUtil;	import flash.display.Loader;	import flash.display.Sprite;	import flash.events.Event;	import flash.events.IOErrorEvent;	import flash.geom.Rectangle;	import flash.net.URLRequest;	import flash.text.TextField;	import flash.utils.getDefinitionByName;	/**	 * @author mo	 */	public class TweetSprite extends NodeSprite {		public static const EXPANDED : String = "EXPANDED";		public static const COLLAPSED : String = "COLLAPSED";		private static const EXPANDED_WIDTH : Number = 330;		private static const EXPANDED_HEIGHT : Number = 100;		private static const COLLAPSED_WIDTH : Number = 50;		private static const COLLAPSED_HEIGHT : Number = 50;		public static var baseScale : Number = 1;		public var text_tf : TextField;		public var author_tf : TextField;		private var newIcon : Sprite;		public var lightBG : Sprite;		public var darkBG : Sprite;		public var ago_tf : TextField;		private var imageLoader : Loader;		public var axis : Axis;		private var endBounds : Rectangle;		private var targetWidth : Number;		private var targetHeight : Number;		public var retweetSourceHighlighted : Boolean;		public var retweetTargetHighlighted : Boolean;		public var referenceSourceHighlighted : Boolean;		public var referenceTargetHighlighted : Boolean;		public var activationLevel : Number;		public var isNew : Boolean;		private var imageHolder : Sprite;		public function TweetSprite(o : Object = null) {			imageLoader = new Loader();			addChild(imageLoader);			super();			mouseChildren = false;			data = o;			renderer = null;			appearance = COLLAPSED;			text_tf.mouseEnabled = author_tf.mouseEnabled = ago_tf.mouseEnabled = false;			cacheAsBitmap = true;			updateActivationLevel();			renderAppearance();		}		override public function set data(o : Object) : void {			if (o is TweetData) {				super.data = o;				text_tf.text = (o as TweetData).text;				author_tf.text = (o as TweetData).user;				updateAgoField();				// loadRetweets();				loadImage();			} else {				throw new Error("SearchResultData or StatusData expected");			}		}		private function updateAgoField() : void {			ago_tf.htmlText = TweetUtil.returnShortTweetAge((data as TweetData).createdAt);		}		private function loadImage() : void {			var imageURL : String = (data as TweetData).userProfileImage;			imageLoader.load(new URLRequest(imageURL));			imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPicLoaded, false, 0, true);			imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onPicLoadError, false, 0, true);		}		private function onPicLoadError(event : IOErrorEvent) : void {			trace("error loading pic ", (data as TweetData).userProfileImage);		}		private function onPicLoaded(event : Event) : void {			imageHolder = new Sprite();			addChild(imageHolder);			imageHolder.addChild(imageLoader);			imageHolder.width = 50;			imageHolder.height = 50;			imageHolder.scaleX = imageHolder.scaleY = Math.min(imageHolder.scaleX, imageHolder.scaleY);		}		private var _appearance : String;		public function get appearance() : String {			return _appearance;		}		public function set appearance(appearance : String) : void {			if (appearance != _appearance) {				_appearance = appearance;				if (appearance == EXPANDED) {					updateAgoField();				}				// layout();			}		}		public var highlighted : Boolean = false;		public function getEndBounds(t : Transitioner) : Rectangle {			if (!endBounds) {				var x : Number = Number(t.$(this).x != null ? t.$(this).x : x);				var y : Number = Number(t.$(this).y != null ? t.$(this).y : y);				var w : Number = t.$(this).scaleX != null ? Number(t.$(this).scaleX) * targetWidth : scaleX * targetWidth;				var h : Number = t.$(this).scaleY != null ? Number(t.$(this).scaleY) * targetHeight : scaleY * targetHeight;				endBounds = new Rectangle(x, y, w, h);			}			return endBounds;		}		public function invalidateEndBounds() : void {			endBounds = null;		}		public function renderAppearance(t : Transitioner = null) : void {			t = Transitioner.instance(t);			switch (appearance) {				case EXPANDED :					t.$(text_tf).visible = true;					t.$(author_tf).visible = true;					t.$(ago_tf).visible = true;					t.$(author_tf).alpha = 1;					t.$(text_tf).alpha = 1;					t.$(ago_tf).alpha = 1;					targetWidth = EXPANDED_WIDTH;					targetHeight = EXPANDED_HEIGHT;					lightBG.visible = true;					t.$(lightBG).width = EXPANDED_WIDTH;					t.$(lightBG).height = EXPANDED_HEIGHT;					t.$(lightBG).alpha = 1;					darkBG.visible = false;					darkBG.width = darkBG.height = darkBG.alpha = 0;					break;				case COLLAPSED :					t.$(text_tf).visible = false;					t.$(author_tf).visible = false;					t.$(ago_tf).visible = false;					t.$(author_tf).alpha = 0;					t.$(text_tf).alpha = 0;					t.$(ago_tf).alpha = 0;					targetWidth = COLLAPSED_WIDTH;					targetHeight = COLLAPSED_HEIGHT;					darkBG.visible = true;					t.$(darkBG).width = COLLAPSED_WIDTH;					t.$(darkBG).height = COLLAPSED_HEIGHT;					t.$(darkBG).alpha = 1;					lightBG.visible = false;					lightBG.width = lightBG.height = lightBG.alpha = 0;					break;			}		}		public function updateAppearance(t : Transitioner, inFocusArea : Boolean = false, middleY : Number = 0) : void {			appearance = ((inFocusArea || retweetTargetHighlighted || referenceTargetHighlighted || referenceSourceHighlighted) ? EXPANDED : COLLAPSED);			renderAppearance(t);			activationLevel = updateActivationLevel();			renderNewIcon();			if (highlighted) {				t.$(this).scaleX = t.$(this).scaleY = 16.0 / 13.0;				t.$(imageLoader).alpha = 1;				isNew = false;			} else if (appearance == EXPANDED) {				t.$(this).scaleX = t.$(this).scaleY = 10.0 / 13.0;				t.$(imageLoader).alpha = 1;			} else {				t.$(this).scaleX = t.$(this).scaleY = Maths.linearInterp(activationLevel, .2, 1) * baseScale;				t.$(imageLoader).alpha = Math.min(1, activationLevel * 2 + .2);			}			invalidateEndBounds();			t.$(this).y = middleY - getEndBounds(t).height;			var xx : Number = 0;			if (highlighted) {				xx = axis.x1 + .5 * (axis.x2 - axis.x1) - getEndBounds(t).width * .5;			} else {				xx = axis.X(data.date);				xx -= axis.axisScale.interpolate(data.date) * getEndBounds(t).width;			}			// xx -= getEndBounds(t).width * .5;			if (xx < 0) xx = 0;			if (xx > 1200 - getEndBounds(t).width) xx = 1200 - getEndBounds(t).width;			xx = Math.floor(xx);			t.$(this).x = xx;			invalidateEndBounds();		}		private function renderNewIcon() : void {			if (isNew && !newIcon) {				newIcon = new (getDefinitionByName("NewIcon") as Class)() as Sprite;				// newIcon.scaleX = newIcon.scaleY = 1.5;				newIcon.x = newIcon.y = -10;				addChild(newIcon);			} else if (!isNew && newIcon) {				removeChild(newIcon);				newIcon = null;			}		}		public function updateEdges(t : Transitioner) : void {			var totalHeight : Number = 0;			visitEdges(function(tc : TweetConnection) : void {				tc.updateSize(t);				totalHeight += tc.targetHeight + 1;			}, NodeSprite.IN_LINKS);			sortEdgesBy(NodeSprite.IN_LINKS, "targetAngle");			invalidateEndBounds();			var b : Rectangle = getEndBounds(t);			var currentX : Number = b.right + 1;			var currentY : Number = (appearance == EXPANDED) ? b.top + b.height * .5 - totalHeight * .5 : b.top;			// var maxSize : Number = 0;			visitEdges(function(tc : TweetConnection) : void {				t.$(tc).x = currentX;				t.$(tc).y = currentY;				tc.updatePositions(t);				currentY += tc.targetHeight + 1;				/*				// make grid, does not work that well because connections overlap much more				maxSize = Math.max(maxSize, tc.targetHeight);				if(currentY > b.bottom) {				currentY = b.top;				currentX += maxSize + 1;				maxSize = 0;				}				 * 				 */			}, NodeSprite.IN_LINKS);		}		private function updateActivationLevel() : Number {			var s : Number = 0;			if (highlighted) return 1.1;			if (appearance == EXPANDED) return 1.05;			s = 0;			s += .25 * Math.sqrt(inDegree);			s += .1 * Math.sqrt(outDegree);			s += .33 * Number(isNew);			s += .2 * Number(retweetSourceHighlighted);			s += .4 * Number(retweetTargetHighlighted);			s += .1 * Number(referenceSourceHighlighted);			s += .2 * Number(referenceTargetHighlighted);			s = Math.min(1, s);			return s;		}	}}