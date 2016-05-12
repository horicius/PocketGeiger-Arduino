import twitter4j.conf.*;
import twitter4j.auth.*;
import twitter4j.api.*;
import java.util.*;
import processing.serial.*;
import processing.net.*;
import processing.data.*;
import java.net.*;
import java.io.*;

final String IPFIND_KEY = "65f0a16e-3117-459a-bd0b-aa776b38e4c6";
final String OAUTH_CONSUMER_KEY = "SWMJlnK0O0QkQVonodAsjeKqQ";
final String OAUTH_CONSUMER_SECRET = "A6St62Y6ZwQ1eB7zi69WKEGsojTZ64m1TZhhUbbxd9tIGKJHlO";
final String OAUTH_ACCESS_TOKEN = "709731814693330948-7XbJiFCjsTMbM67fq6KB14kPGcFNvtO";
final String OAUTH_ACCESS_TOKEN_SECRET = "pBMIHNt3mWIUsynDTcqI9ASYQzEES5TsP6KhZtHjRiRx9";
final int iFrequencyOfPublication = 7;
Serial myPort;        // The serial port
String inString;  // Input string from serial port
int lf = 10;      // ASCII linefeed 
int m;
boolean posted=false;
Client oGeoIpClient;
URL url;
String sGeoData;
String sMyIp;
processing.data.JSONObject oGeoResponse;
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

void draw(){
  m = minute();
  tweet();
}

void serialEvent(Serial p) {
  inString = p.readString();
}

void tweet()
{
  
  if (m%iFrequencyOfPublication==0 && inString!=null && float(trim(inString)) > 0.00) {

    try
    {
      
      if (!posted) {
        
        URL oPublicIp       = new URL("https://api.ipify.org");
        BufferedReader inIp = new BufferedReader(new InputStreamReader(oPublicIp.openStream()));
        String sMyIp        = inIp.readLine(); //you get the IP as a String
        
        String sIpUrl    = "https://ipfind.co/?ip=" + sMyIp + "&auth="+IPFIND_KEY;
        processing.data.JSONObject oGeoResponse = loadJSONObject(sIpUrl);
        float sLatitude  = oGeoResponse.getFloat("latitude");
        float sLongitude = oGeoResponse.getFloat("longitude");
        String sCountry  = oGeoResponse.getString("country");
        String sCity     = oGeoResponse.getString("city");
        int iMin         = minute();
        String sMin      = str(iMin);
        if (iMin < 10) {
           sMin = "0"+sMin;
        }
        
        posted=true;
        Status status = twitter.updateStatus("Radioactivity level in " + sCountry 
          + ", " + sCity + "(" + sLatitude + ", " + sLongitude + "), at " + year() + "-" + month() + "-" + day() 
          + " " + hour() + ":" + sMin + " is : " + trim(inString) + " uSv/h, #PocketGeiger #Arduino #Processing");
        System.out.println("Status updated to [" + status.getText() + "].");
      }
    }
    catch (Exception te)
    {
      System.out.println("Error: "+ te.getMessage());
    }
  } else {
    posted=false;
  }
}