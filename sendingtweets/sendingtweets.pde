import twitter4j.conf.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import java.util.*;
import processing.serial.*;
import processing.net.*;
import processing.data.*;
import java.net.*;
import java.io.*;

final String IPFIND_KEY                = " "; // Find public ip api key
final String OAUTH_CONSUMER_KEY        = " "; // Twitter consumer key
final String OAUTH_CONSUMER_SECRET     = " "; // Twitter secret key
final String OAUTH_ACCESS_TOKEN        = " "; // Twitter access token
final String OAUTH_ACCESS_TOKEN_SECRET = " "; // Twitter secret access token
final int iFrequencyOfPublication      = 30; // Min to post at
Serial myPort;        // The serial port
String inString;  // Input string from serial port
final int lf = 10;      // ASCII linefeed 
boolean posted = false;
Client oGeoIpClient;
URL url;
String sGeoData;
Twitter twitter;

void setup()
{
  //size(800,600);

    ConfigurationBuilder cb = new ConfigurationBuilder();
    cb.setOAuthConsumerKey(OAUTH_CONSUMER_KEY);
    cb.setOAuthConsumerSecret(OAUTH_CONSUMER_SECRET);
    cb.setOAuthAccessToken(OAUTH_ACCESS_TOKEN);
    cb.setOAuthAccessTokenSecret(OAUTH_ACCESS_TOKEN_SECRET);

    TwitterFactory tf = new TwitterFactory(cb.build());
    twitter = tf.getInstance();

    myPort = new Serial(this, Serial.list()[0], 9600);
    myPort.bufferUntil(lf);
}

void draw() {
  int m = minute();
  tweet(m);
}

void serialEvent(Serial p) {
  inString = p.readString();
}

String getMyIp() {
  String sMyIp = "";
  try {
    URL oPublicIp       = new URL("https://api.ipify.org");
    BufferedReader inIp = new BufferedReader(new InputStreamReader(oPublicIp.openStream()));
    sMyIp               = inIp.readLine(); //you get the public IP as a String
  } catch (Exception e) {
    System.out.println("Could not fetch public ip");
  }
  return sMyIp;
}

processing.data.JSONObject getLocation(String sMyIp) {
  processing.data.JSONObject oGeoResponse = new processing.data.JSONObject();
  try {
    String sIpUrl    = "https://ipfind.co/?ip=" + sMyIp + "&auth="+IPFIND_KEY;
    oGeoResponse = loadJSONObject(sIpUrl); // Get location data based on public ip
  } catch (Exception e) {
    System.out.println("Could not fetch location");
  }
  return oGeoResponse;
}

String constructTwitterMessage(processing.data.JSONObject oGeoResponse, String inString) {
  float fLatitude  = oGeoResponse.getFloat("latitude");
  float fLongitude = oGeoResponse.getFloat("longitude");
  String sCountry  = oGeoResponse.getString("country");
  String sCity     = oGeoResponse.getString("city");
  int iMin         = minute();
  String sMin      = str(iMin);
  if (iMin < 10) {
     sMin = "0"+sMin; // Trailing 0 for mins < 10
  }
  
  String sMessage = "Radioactivity level in " + sCountry 
          + ", " + sCity + "(" + str(fLatitude) + ", " + str(fLongitude) + "), at " + year() + "-" + month() + "-" + day() 
          + " " + hour() + ":" + sMin + " is : " + trim(inString) + " uSv/h, #PocketGeiger #Arduino #Processing";
        
  return sMessage;
  
}

Boolean shouldPost(String inString, int m) {
  return m%iFrequencyOfPublication==0 && inString!=null && float(trim(inString)) > 0.00;
}

void tweet(int m) {
  if (!posted && shouldPost(inString, m)) {
    try
    {      
      processing.data.JSONObject oGeoResponse = getLocation(getMyIp());
      posted=true;
      Status status = twitter.updateStatus(constructTwitterMessage(oGeoResponse, inString)); // Construct message to post to twitter
      System.out.println("Status updated to [" + status.getText() + "].");
    }
    catch (Exception te)
    {
      System.out.println("Error: "+ te.getMessage());
      posted = false;
    }
  }
}