//
#pragma once  
#include "mp4v2.h"

#define  _NALU_SPS_  0
#define  _NALU_PPS_  1
#define  _NALU_I_    2
#define  _NALU_P_    3

#define WAVE_FORMAT_G711                   0x7A19
#define WAVE_FORMAT_G711U                  0x7A25
#define WAVE_FORMAT_AAC                    0x7A26


typedef int DWORD;
typedef char BYTE;

typedef struct _MP4ENC_NaluUnit
{
    int frameType;
    int frameLen;  //nalu长度，不包括00 00 00 01
    unsigned char *pframeBuf;   //不包括00 00 00 01
}MP4ENC_NaluUnit;



class CMp4Encoder
{
public:
    CMp4Encoder(char *strFilePath, int vWidth, int vHeight, int vRate, int vTimeScale, unsigned int audioFormat, unsigned int audioSampleRate, unsigned int audioChannel, int bitsPerSample);
	int WriteVideoTrack(BYTE*,int);
    int WriteAudioTrack(BYTE*,int);
    int WriteVideoTrack(BYTE* pframeBuf,int frameSize,unsigned char **ppsBuff,int *ppsLen,unsigned char **spsBuff,int *spsLen);
    int WriteH264SPS(unsigned char* pBuf,int len);
    int WriteH264PPS(unsigned char* pBuf,int len);
	void CloseMp4Encoder();
    bool m_bRecord;
    
//----------------------------------------------------------- Attributes
private:
	int m_vWidth,m_vHeight,m_vFrateR,m_vTimeScale;
	MP4FileHandle m_mp4FHandle;
    unsigned int m_vFrameDur;
	MP4TrackId m_vTrackId,m_aTrackId;
    bool   m_bGetSpsSlice;
    bool   m_bGetPpsSlice;
    bool   m_bGetIFrame;
    unsigned int m_audioFormat;
    unsigned int m_vLastFrameDur;
};



