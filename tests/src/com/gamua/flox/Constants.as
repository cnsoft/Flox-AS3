package com.gamua.flox 
{
    import com.gamua.flox.utils.createURL;

    public class Constants
    {
        public static const PRODUCTION_SERVER:Boolean = true;
        
        public static const GAME_ID:String = "gamua-unit-tests";
        public static const LEADERBOARD_ID:String = "default";
        
        public static function get GAME_KEY():String
        {
            return PRODUCTION_SERVER ? "150a1bb6-b33d-4eb3-8848-23051f200359" :
                                       "58d92a16-a0ba-4c70-8539-2ef6bf6fa6ed";
        }
        
        public static function get BASE_URL():String
        {
            return PRODUCTION_SERVER ? "https://www.flox.cc/api" :
                                       "https://flox-by-gamua-test.appspot.com/api";
        }
        
        public static function get ENABLED_HERO_KEY():String
        {
            return PRODUCTION_SERVER ? "zjCXJefGy6Dzdm5W" : "B3Lkg2g1cy2Fh4zf";
        }
        
        public static function get DISABLED_HERO_KEY():String
        {
            return PRODUCTION_SERVER ? "tz0H1RFjjp4Jmb3T" : "GYhcx9jw5g36nnMf";
        }
        
        public static function createGameUrl(...args):String
        {
            return createURL("games", GAME_ID, createURL(args)); 
        }
        
        public static function createLeaderboardUrl(...args):String
        {
            return createURL("games", GAME_ID, "leaderboards", LEADERBOARD_ID, createURL(args));
        }
        
        public static function initFlox(reportAnalytics:Boolean=false):void
        {
            Flox.traceLogs = false;
            Flox.reportAnalytics = reportAnalytics;
            Flox.initWithBaseURL(GAME_ID, GAME_KEY, Flox.VERSION, BASE_URL);
        }
        
        public static function initFloxForGameOverQuota():void
        {
            const gameID:String  = PRODUCTION_SERVER ? "9LSCZS3yQlF1dGFr" : "ofBuqx6kqSsY9iqb";
            const gameKey:String = PRODUCTION_SERVER ? "iamDM9f36SS3Uucp" : "rnuW98IDQNoEWLJu";
            
            Flox.traceLogs = false;
            Flox.reportAnalytics = false;
            Flox.initWithBaseURL(gameID, gameKey, Flox.VERSION, BASE_URL);
        }
    }
}