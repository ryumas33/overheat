//20160908, for the tournament
String mode = "control1"; //mapping or control + 1..3

import processing.serial.*;
import processing.opengl.*;
Serial port;
PrintWriter writer;
int[] buf     = new int[100];
int[] inByte  = new int[100];
String[] save_map = {};
String[] load_map = {};
long progress = 0;
float risk = 0.0;
boolean in_progress = false;
boolean in_control = false;
float m_duty = 0.0;

float[] omega_vec         = {
  0.0, 0.0, 0.0
};
float[] acc_vec           = {
  0.0, 0.0, 0.0
};
float[] mag_vec           = {
  0.0, 0.0, 0.0
};
float   acc_norm          = 0.0;
float   mag_norm          = 0.0;
float   mag_cor_norm      = 0.0;
float   temperature       = 0.0;
float   voltage_Bat       = 0.0;
float   voltage_Lipo      = 0.0;
int     isSlope           =0;
int     isStop            =0;
int     isCurve           =0;
long    time              = 0;

void setup() 
{
  size(650, 600, P3D);
  frameRate(60);
  port = new Serial(this, "/dev/tty.RNBT-400D-RNI-SPP", 115200);
  if(mode == "control1"){
    load_map = loadStrings("mapping1.txt");
  }else if(mode == "control2"){
    load_map = loadStrings("mapping2.txt");
  }else if(mode == "control3"){
    load_map = loadStrings("mapping3.txt");
  }
}

void draw()
{
  background(0);  
  writeSenValue();
}

void serialEvent(Serial p)
{
  if (port.available() != 0)
  {
    for (int i=43; i>=1; i--)
    {
      buf[i] = buf[i-1];
    }
    buf[0] = port.read();
  }

  if (buf[39] == 0x54  
      && buf[40] == 0x52 
      && buf[41] == 0xff 
      && buf[42] == 0xff )
  {
    for (int i = 0; i < 43; i ++)
    {
      inByte[i] = buf[42-i];
    }
    port.clear();
    
    omega_vec[0] = radians(((float)(concatenate2Byte_int(inByte[17], inByte[16]) ) )/16.4);
    omega_vec[1] = radians(((float)(concatenate2Byte_int(inByte[19], inByte[18]) ) )/16.4);
    omega_vec[2] = radians(((float)(concatenate2Byte_int(inByte[21], inByte[20]) ) )/16.4);
    acc_vec[0]   = (float)(concatenate2Byte_int(inByte[9], inByte[8]))/2048.0; 
    acc_vec[1]   = (float)(concatenate2Byte_int(inByte[11], inByte[10]))/2048.0; 
    acc_vec[2]   = (float)(concatenate2Byte_int(inByte[13], inByte[12]))/2048.0;  
    acc_norm = sqrt(acc_vec[0]*acc_vec[0]+acc_vec[1]*acc_vec[1]+acc_vec[2]*acc_vec[2]);
    mag_vec[0]   = (float)(concatenate2Byte_int(inByte[23], inByte[22])) * 0.3;  
    mag_vec[1]   = (float)(concatenate2Byte_int(inByte[25], inByte[24])) * 0.3; 
    mag_vec[2]   = (float)(concatenate2Byte_int(inByte[27], inByte[26])) * 0.3;
    mag_norm = sqrt(mag_vec[0]*mag_vec[0]+mag_vec[1]*mag_vec[1]+mag_vec[2]*mag_vec[2]);
    temperature = (float)(concatenate2Byte_int(inByte[15], inByte[14]))/340 + 35.0;
    isStop  = inByte[32];
    isCurve = inByte[33];
    isSlope = inByte[34];
    voltage_Bat = (float)(concatenate2Byte_uint(inByte[40], inByte[39]) / 13107.0 );
    voltage_Lipo = (float)(concatenate2Byte_uint(inByte[42], inByte[41]) / 13107.0 );
    time = inByte[35] + (inByte[36]<<8) + (inByte[37]<<16) + (inByte[38]<<24);
    
    if(in_progress){
      save_map = (String[])append(save_map,str(isCurve+isSlope));
      progress++;
    }
    if(in_control){
      risk = 0;
      for(int i = 0; i < 10; i++){
        risk += int(load_map[int(progress/2 + 10 + i)]);
      }
      m_duty = 1 - risk / 25.0;
      //manual countermoving
      
      port.write(command0(m_duty));
      println(m_duty);
    }
  }
}

void writeSenValue()
{
  fill(255, 255, 255);
  textSize(20);
  text("accX[g]", 10, 20);
  text("accY[g]", 10, 40);
  text("accZ[g]", 10, 60);
  text("|a|=", 10, 80);
  text(acc_vec[0], 90, 20);
  text(acc_vec[1], 90, 40);
  text(acc_vec[2], 90, 60); 
  text(acc_norm, 60, 80); 

  text("magX[uT]", 180, 20);
  text("magY[uT]", 180, 40);
  text("magZ[uT]", 180, 60);
  text("|m|=", 180, 80);
  text(mag_vec[0], 300, 20);
  text(mag_vec[1], 300, 40);
  text(mag_vec[2], 300, 60);  
  text(mag_norm, 230, 80);  

  text("omegaX[deg/s]", 400, 20);
  text("omegaY[deg/s]", 400, 40);
  text("omegaZ[deg/s]", 400, 60);
  text(degrees(omega_vec[0]), 550, 20);
  text(degrees(omega_vec[1]), 550, 40);
  text(degrees(omega_vec[2]), 550, 60); 

  text(temperature, 400, 80);
  text("[degree C]", 500, 80);

  text(voltage_Bat, 170, 100);
  text("Voltage_Bat [V]", 10, 100);
  
  text(voltage_Lipo, 170, 120);
  text("Voltage_Lipo [V]", 10, 120);
  
  text(isSlope, 160, 140);
  text("isSlope", 10, 140);
  text(isCurve, 160, 160);
  text("isCurve", 10, 160);
  text(isStop,  160, 180);
  text("isStop",  10, 180);
  text(time,    160, 200);
  text("time[ms]",  10, 200);
}

int concatenate2Byte_int(int H_byte, int L_byte) {
  int con; 
  con = L_byte + (H_byte<<8);
  if (con > 32767) {
    con -=  65536;
  }
  return con;
}

int concatenate2Byte_uint(int H_byte, int L_byte) {
  int con; 
  con = L_byte + (H_byte<<8);
  return con;
}

void keyPressed() {
if (key == CODED) {
    if (keyCode == LEFT) {  
      if(m_duty > -1){
        m_duty -= 0.1;
      }
      port.write(command0(m_duty));
    }else if(keyCode == RIGHT){
      if(m_duty < 1){
        m_duty += 0.1;
      }
      port.write(command0(m_duty));
    }else if(keyCode == UP){
      m_duty = 1.0;
      port.write(command0(m_duty));
    }
  }
  if (keyCode == CONTROL){
    in_progress = true;
    if(mode == "mapping1"||mode == "mapping2"||mode == "mapping3"){
      m_duty = 0.5;
    }else if(mode == "control1"||mode == "control2"||mode == "control3"){
      in_control = true;
      m_duty = 1.0;
    }
    port.write(command0(m_duty));
  }
  if (keyCode == ALT){
    in_progress = false;
    port.write(command0(m_duty));
    if(mode == "mapping1"||mode == "mapping2"||mode == "mapping3"){
      saveStrings(mode+".txt", save_map);
      m_duty = 0.0;
    }else if(mode == "control1"||mode == "control2"||mode == "control3"){
      in_control = false;
      m_duty = 0.0;
    }
    port.write(command0(m_duty));
  }
}

byte[] command0(float duty){
  byte[] command = new byte[10];
  int int_duty;
  int duty_L;
  int duty_H;
  
  int_duty = (int)(duty * 32767.0);
  if(int_duty<0)
  {
    int_duty += 65535;
  }
  duty_L = int_duty & 0x000000ff ;
  duty_H = (int_duty & 0x0000ff00)>>8;
  
  //header
  command[0] =  99;
  command[1] = 109;
  command[2] = 100;
  //id 
  command[3] =   0;
  //value
  command[4] = byte(duty_L);
  command[5] = byte(duty_H);
  //dummy
  command[6] = 0;
  command[7] = 0;
  command[8] = 0;
  command[9] = 0;
  
  return command;
}