/*   Copyright 2010, Moritz StefanerLicensed under the Apache License, Version 2.0 (the "License");you may not use this file except in compliance with the License.You may obtain a copy of the License athttp://www.apache.org/licenses/LICENSE-2.0Unless required by applicable law or agreed to in writing, softwaredistributed under the License is distributed on an "AS IS" BASIS,WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.See the License for the specific language governing permissions andlimitations under the License.    */package eu.stefaner.revisit {	import flare.util.Dates;	import com.swfjunkie.tweetr.Tweetr;	/**	 * @author mo	 */	public class Settings {		// externally configurable		public static var maxItems : int = 300;		public static var showOnlyToday : Boolean = false;		public static var twitterProxyURL : String;		public static var searchterms : Array = ["@twitter"];		public static var appTitle : String;		// internal		// public static var minDate : Date = Dates.roundTime(new Date(), Dates.DAYS);		public static var minDate : Date = null;		public static var maxDate : Date = null;		public static var resultsPerPage : int;		public static var numPreloadPages : int;		public static var advanceSteps : int = 1;		public static var windowSize : int = 0;		public static var minSpacing : Number = 5;		public static var transitionLength : Number = 1;		public static var advanceTime : Number = 6000;		public static var loadTime : Number = 10000;		public static var retweetColor : uint = 0xFF32CCFF;		public static var atReplyColor : uint = 0xFF99FF99;		public static var showStatus : Boolean = true;		public static var tweetConnectionAlpha : Number = .33;		public static var tweetConnectionDimmedAlpha : Number = .16;		public static var tweetConnectionCollapsedAlpha : Number = .66;		public static var focusWindowWidth : Number = 600;		public static var minAxisWidth : Number = 150;		// see 5 special		public static var STANDALONE : Boolean = false;		public static function overwriteDefaults(params : Object) : void {			if (params) {				// overwrite defaults				maxItems = params.maxItems || maxItems ;				resultsPerPage = Math.min(100, maxItems);				numPreloadPages = Math.ceil(maxItems / resultsPerPage);				showOnlyToday = (params.showOnlyToday == "true") || showOnlyToday;				twitterProxyURL = params.twitterProxyURL || twitterProxyURL ;				if (params.searchterms) {					searchterms = params.searchterms.split(",");				}				appTitle = params.appTitle || appTitle;			}			if (showOnlyToday) {				minDate = Dates.addHours(Dates.roundTime(new Date(), Dates.DAYS), 7);			}			if (twitterProxyURL) {				Tweetr.URL_TWITTER_SEARCH_OVERRIDE = twitterProxyURL;			}			if (!appTitle) {				appTitle = searchterms.join(",");			}		}	}}