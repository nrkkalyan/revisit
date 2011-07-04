﻿/*   Copyright 2010, Moritz StefanerLicensed under the Apache License, Version 2.0 (the "License");you may not use this file except in compliance with the License.You may obtain a copy of the License athttp://www.apache.org/licenses/LICENSE-2.0Unless required by applicable law or agreed to in writing, softwaredistributed under the License is distributed on an "AS IS" BASIS,WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.See the License for the specific language governing permissions andlimitations under the License. */package eu.stefaner.revisit {	import com.swfjunkie.tweetr.Tweetr;	import com.swfjunkie.tweetr.data.objects.SearchResultData;	import com.swfjunkie.tweetr.events.TweetEvent;	import flare.util.Strings;	import flash.display.SimpleButton;	import flash.display.Sprite;	import flash.display.StageAlign;	import flash.display.StageDisplayState;	import flash.events.Event;	import flash.events.FullScreenEvent;	import flash.events.KeyboardEvent;	import flash.events.MouseEvent;	import flash.events.TimerEvent;	import flash.geom.Rectangle;	import flash.text.TextField;	import flash.ui.Keyboard;	import flash.utils.Timer;	import gs.TweenFilterLite;	import nl.demonsters.debugger.MonsterDebugger;	public class App extends Sprite {		public static var monsterDebugger : MonsterDebugger;		private static const LIVEUPDATES : String = "LIVEUPDATES";		private static const ARCHIVE : String = "ARCHIVE";		private static const NEW_TWEETS : String = "NEW_TWEETS";		private static const OVERVIEW : String = "OVERVIEW";		private static const RANDOM : String = "RANDOM";		private var searchTweetr : Tweetr;		private var loadTimer : Timer;		private var searchRunning : Boolean;		private var advanceTimer : Timer;		private var visualization : TweetVisualization;		private var latestId : Number = 0;		public var search_tf : TextField;		public var settings : Class = Settings;		public var status_tf : TextField;		private var loadCounter : Number = 1;		public var newTweets : Array = [];		private var advanceTimerTime : Number = new Date().time;		private var searchMode : String = "ARCHIVE";		public var numTweets_tf : TextField;		public var numRetweets_tf : TextField;		public var numReplies_tf : TextField;		public var numNew_tf : TextField;		public var appTitle_tf : TextField;		public var footer : Sprite;		public var newIcon : Sprite;		public var icons : Sprite;		private var displayMode : String;		public var fullscreen_btn : SimpleButton;		public function App() {			Settings.overwriteDefaults(loaderInfo.parameters);			App.monsterDebugger = new MonsterDebugger(this);			initStage();			initKeyControl();			initVis();			initTweetrs();			loadData();			initTimers();			initIconsAndTitle();			addEventListener(Event.ENTER_FRAME, onEnterFrame);		}		private function initIconsAndTitle() : void {			displayStatus("starting up");			appTitle_tf.text = Settings.appTitle;			status_tf.alpha = 0;			footer["description_tf"].text = Strings.format(footer["description_tf"].text, Settings.maxItems, Settings.searchterms.join(" OR "));			icons.x = Math.min(fullscreen_btn.x - icons.width - 10, appTitle_tf.x + appTitle_tf.textWidth + 50);			appTitle_tf.width = icons.x - appTitle_tf.x;			numTweets_tf = icons["numTweets_tf"];			numNew_tf = icons["numNew_tf"];			numReplies_tf = icons["numReplies_tf"];			numRetweets_tf = icons["numRetweets_tf"];			newIcon = icons["newIcon"];			icons.alpha = newIcon.alpha = 0;			fullscreen_btn.addEventListener(MouseEvent.CLICK, onFullScreenClick);			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onToggleFullScreen);		}		private function onToggleFullScreen(event : Event) : void {			fullscreen_btn.visible = !(stage.displayState == StageDisplayState.FULL_SCREEN);			if (fullscreen_btn.visible) {				icons.x = Math.min(fullscreen_btn.x - icons.width - 10, appTitle_tf.x + appTitle_tf.textWidth + 50);				appTitle_tf.width = icons.x - appTitle_tf.x;			} else {				icons.x = Math.min(stage.stageWidth - icons.width - 10, appTitle_tf.x + appTitle_tf.textWidth + 50);				appTitle_tf.width = icons.x - appTitle_tf.x;			}		}		private function onFullScreenClick(event : MouseEvent = null) : void {			try {				stage.displayState = StageDisplayState.FULL_SCREEN;				fullscreen_btn.visible = false;			} catch (e : Error) {				fullscreen_btn.visible = true;			}		}		public static function log(target : Object, object : *, color : uint = 0x111111, functions : Boolean = false, depth : int = 4) {			MonsterDebugger.trace(target, object, color, functions, depth);		}		private function displayStatus(string : String) : void {			if (Settings.showStatus) {				status_tf.text = string;				status_tf.alpha = 1;				TweenFilterLite.to(status_tf, 3, {alpha:0});			}			App.log(this, string);		}		private function initStage() : void {			stage.align = StageAlign.TOP_LEFT;		}		private function initKeyControl() : void {			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressedDown);		}		private function onEnterFrame(event : Event) : void {			renderAdvanceTimer();		}		private function renderAdvanceTimer() : void {			graphics.clear();			graphics.beginFill(0x444444);			graphics.drawRect(20, 1, 92 * (new Date().time - advanceTimerTime) / advanceTimer.delay, 3);		}		private function initVis() : void {			visualization = new TweetVisualization(this, new Rectangle(0, 0, stage.stageWidth - 80, stage.stageHeight - 240));			visualization.x = 15;			visualization.y = 100;			addChildAt(visualization, 0);		}		private function keyPressedDown(event : KeyboardEvent) : void {			switch (event.keyCode) {				case Keyboard.LEFT :					visualization.displayPrevious();					resetAdvanceTimer();					break;				case Keyboard.RIGHT :					visualization.displayNext();					resetAdvanceTimer();					break;				case Keyboard.UP :					visualization.advance(5);					resetAdvanceTimer();					break;				case Keyboard.DOWN :					visualization.advance(-5);					resetAdvanceTimer();					break;			}		}		public function onNodeClick(ts : TweetSprite) : void {			visualization.displayTweet(ts);			resetAdvanceTimer();		}		/*  		 * TIMERS		 */		private function initTimers() : void {			loadTimer = new Timer(Settings.loadTime);			loadTimer.start();			loadTimer.addEventListener(TimerEvent.TIMER, onLoadTick);			advanceTimer = new Timer(Settings.advanceTime);			advanceTimer.start();			advanceTimer.addEventListener(TimerEvent.TIMER, onAdvanceTick);		}		private function onLoadTick(event : TimerEvent) : void {			loadData();		}		private function onAdvanceTick(event : TimerEvent) : void {			displayNext();		}		private function resetAdvanceTimer() : void {			advanceTimer.reset();			advanceTimer.delay = Math.max(1000, Settings.advanceTime * (1 - Math.sqrt(newTweets.length) / 10));			advanceTimer.start();			advanceTimerTime = new Date().time;		}		private function resetLoadTimer() : void {			loadTimer.reset();			loadTimer.start();		}		private function displayNext() : void {			if (newTweets.length) {				displayMode = NEW_TWEETS;				var ts : TweetSprite = TweetSprite(newTweets.shift());				visualization.displayTweet(ts);			} else if (searchMode == ARCHIVE || displayMode == NEW_TWEETS) {				displayMode = OVERVIEW;				visualization.displayTweet();			} else {				displayMode = RANDOM;				visualization.displayRandom();			}			resetAdvanceTimer();			updateStats();		}		/*		 * DATA LOADING 		 */		private function initTweetrs() : void {			searchTweetr = new Tweetr();			searchTweetr.addEventListener(TweetEvent.COMPLETE, onSearchDataLoaded);			searchTweetr.addEventListener(TweetEvent.FAILED, handleTweetsFail);		}		private function handleTweetsFail(event : TweetEvent) : void {			displayStatus(event.info);			log(this, event, 0x991111);			searchRunning = false;		}		private function loadData() : void {			if (searchMode == ARCHIVE && !searchRunning) {				searchTweetr.search(Settings.searchterms.join("\" OR \""), null, Settings.resultsPerPage, (Settings.numPreloadPages - loadCounter ) + 1);				displayStatus("loading archived results (page " + ((Settings.numPreloadPages - loadCounter ) + 1) + ")");			} else if (searchMode == LIVEUPDATES && !searchRunning) {				displayStatus("loading new tweets");				searchTweetr.search(Settings.searchterms.join("\" OR \""), null, 50, 1, latestId);			}			searchRunning = true;		}		private function onSearchDataLoaded(event : TweetEvent) : void {			searchRunning = false;			var results : Array = [];			var td : TweetData;			if (searchMode == LIVEUPDATES) {				updateLatestId(event.data as String);			}			for each (var tweet:SearchResultData in event.responseArray) {				if (!visualization.tweetByID[tweet.id]) {					td = TweetData.parseSearchResult(tweet);					if (Settings.minDate && td.dateTime < Settings.minDate.time) continue;					if (Settings.maxDate && td.dateTime > Settings.maxDate.time) continue;					results.push(td);				} else {					// Logger.info("already added", tweet.id);				}			}			log(this, event.responseArray.length + " loaded / " + results.length + " new / latestId " + latestId);			if (results.length) {				results.sortOn("dateTime");				for each (td in results) {					var ts : TweetSprite = visualization.addTweetSprite(td);					if (searchMode == LIVEUPDATES) {						newTweets.push(ts);						ts.isNew = true;					}				}				// HACK: fix currentIndex in visualization				for (var i : int = 0;i < visualization.data.nodes.length;i++) {					if (visualization.data.nodes[i] == visualization.highlightedTweet) {						visualization.currentIndex = i;						break;					}				}				displayStatus(results.length + " tweets loaded");				// updateStats();			} else {				displayStatus("no new tweets");			}			if (searchMode == ARCHIVE) {				loadCounter++;				if (loadCounter > Settings.numPreloadPages) {					searchMode = LIVEUPDATES;				} else {					loadData();				}			}		}		private function updateStats() : void {			icons.alpha = 1;			var reducedAlpha : Number = .66;			var template : String = "<font size='24' color='#FFFFFF'>{0}</font> <font size='14' color='#999999'>{1}</font>";			var oldText : String;			oldText = numTweets_tf.text;			numTweets_tf.htmlText = Strings.format(template, visualization.data.nodes.length, "tweets");			if (numTweets_tf.text != oldText) {				numTweets_tf.alpha = 1;				TweenFilterLite.to(numTweets_tf, 3, {alpha:reducedAlpha});			}			var numRetweets : Number = 0;			var numReplies : Number = 0;			for each (var e:TweetConnection in visualization.data.edges) {				if (e.type == "retweet") numRetweets++;				if (e.type == "reference") numReplies++;			}			oldText = numRetweets_tf.text;			numRetweets_tf.htmlText = Strings.format(template, numRetweets, "retweets");			if (numRetweets_tf.text != oldText) {				numRetweets_tf.alpha = 1;				TweenFilterLite.to(numRetweets_tf, 3, {alpha:reducedAlpha});			}			oldText = numReplies_tf.text;			numReplies_tf.htmlText = Strings.format(template, numReplies, "replies");			if (numReplies_tf.text != oldText) {				numReplies_tf.alpha = 1;				TweenFilterLite.to(numReplies_tf, 3, {alpha:reducedAlpha});			}			oldText = numNew_tf.text;			numNew_tf.htmlText = Strings.format(template, newTweets.length, "new");			if (newTweets.length) {				if (numNew_tf.text != oldText) {					numNew_tf.alpha = 1;					TweenFilterLite.to(numNew_tf, 3, {alpha:reducedAlpha});					newIcon.alpha = 1;					TweenFilterLite.to(newIcon, 3, {alpha:reducedAlpha});				}			} else {				TweenFilterLite.to(numNew_tf, 3, {alpha:reducedAlpha});				TweenFilterLite.to(newIcon, 3, {alpha:reducedAlpha});			}		}		private function updateLatestId(s : String) : void {			var re : RegExp = /since_id=(.+?)\" rel=\"refresh\"\/>/g;			var matches : Array = re.exec(s);			if (matches.length > 1) latestId = matches[1];		}	}}