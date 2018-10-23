
#include <string.h>
#include <math.h>
#include <sys/timeb.h>
#include "CMp4Encoder.h"
#include <stdlib.h>


/* AAC object types */
#define MAIN 1
#define LOW  2
#define SSR  3
#define LTP  4

/* Returns the sample rate index */
int GetSRIndex(unsigned int sampleRate) {
    if (92017 <= sampleRate){
        return 0;
    }
    if (75132 <= sampleRate) {
        return 1;
    }
    if (55426 <= sampleRate) {
        return 2;
    }
    if (46009 <= sampleRate) {
        return 3;
    }
    if (37566 <= sampleRate) {
        return 4;
    }
    if (27713 <= sampleRate) {
        return 5;
    }
    if (23004 <= sampleRate) {
        return 6;
    }
    if (18783 <= sampleRate) {
        return 7;
    }
    if (13856 <= sampleRate) {
        return 8;
    }
    if (11502 <= sampleRate) {
        return 8;
    }
    if (9391 <= sampleRate) {
        return 10;
    }
    return 11;
}

void getESConfig(int8_t type,int sampleRate,int channels,int8_t result[2] ) {
    unsigned char config[2]={0};
    int sIndex = GetSRIndex(sampleRate);
    int8_t sampleIndex = sIndex;
    
    //0000 0000
    
    unsigned char1 = 0x00;
    unsigned char2 = 0x00;
    
    type = type << 3;
    char1 = char1 | type;
    
    int8_t sampleIndex2 = sampleIndex << 7;
    sampleIndex = sampleIndex >> 1;
    
    char1 = char1 | sampleIndex;
    
    config[0] = char1;
    
    char2 = char2 | sampleIndex2;
    int8_t channelsInt8 = channels;
    channelsInt8 = channelsInt8 << 3;
    char2 = char2 | channelsInt8;
    
    config[1] = char2;
    memcpy(result, config, 2);
}


typedef enum MEDIA_FRAME_TYPE
{
    MEDIA_FRAME_UNVALID    = 0,
    MEDIA_FRAME_VIDEO    = 1,// “Ù∆µ
    MEDIA_FRAME_AUDIO    = 2//  ”∆µ
}MEDIA_FRAME_TYPE_E;



static int ReadOneNaluFromBuf(const unsigned char *buffer,
                              unsigned int nBufferSize,
                              unsigned int offSet,
                              MP4ENC_NaluUnit &nalu);


 CMp4Encoder::CMp4Encoder(char *strFilePath,
                          int vWidth,
                          int vHeight,
                          int vRate,
                          int vTimeScale,
                          unsigned int audioFormat,
                          unsigned int audioSampleRate,
                          unsigned int audioChannel,
                          int bitsPerSample)
{
    m_mp4FHandle = NULL;
    m_aTrackId = MP4_INVALID_TRACK_ID;
    m_vTrackId = MP4_INVALID_TRACK_ID;
    m_vFrameDur = 0;
    //------------------------------------------------------------------------------------- file handle
    m_vWidth = vWidth;
    m_vHeight = vHeight;
    m_vFrateR = vRate;
    m_vTimeScale = 90000;
    m_bGetSpsSlice = false;
    m_bGetPpsSlice = false;
    m_bGetIFrame = false;
    m_vLastFrameDur = 0;
    m_bRecord = true;
    m_mp4FHandle = MP4Create(strFilePath);
    if (m_mp4FHandle == MP4_INVALID_FILE_HANDLE)
    {
        printf("MP4Create failed\n");
        return ;
    }
    MP4SetTimeScale(m_mp4FHandle, m_vTimeScale);
    //------------------------------------------------------------------------------------- audio track
    m_audioFormat = audioFormat;
    switch (audioFormat)
    {
        case WAVE_FORMAT_G711:
        {
            //alaw format
            m_aTrackId = MP4AddALawAudioTrack(m_mp4FHandle, audioSampleRate);
            MP4SetTrackIntegerProperty(m_mp4FHandle, m_aTrackId, "mdia.minf.stbl.stsd.alaw.channels", 1);
            MP4SetTrackIntegerProperty(m_mp4FHandle, m_aTrackId, "mdia.minf.stbl.stsd.alaw.sampleSize", 8);
        }
            break;
        case WAVE_FORMAT_G711U:
        {
            //ulaw format
            m_aTrackId = MP4AddULawAudioTrack(m_mp4FHandle, audioSampleRate);
            MP4SetTrackIntegerProperty(m_mp4FHandle, m_aTrackId, "mdia.minf.stbl.stsd.ulaw.channels", 1);
        }
            break;
        case WAVE_FORMAT_AAC:
        {
            //AAC format
            m_aTrackId = MP4AddAudioTrack(m_mp4FHandle, audioSampleRate,1024, MP4_MPEG4_AUDIO_TYPE);
            if (m_aTrackId == MP4_INVALID_TRACK_ID){
                printf("\n MP4AddAudioTrack failed! trackId:%d\n",m_aTrackId);
                return;
            }
            //
            MP4SetAudioProfileLevel(m_mp4FHandle, 0x2);
            
                                                //
            /*
             在使用MP4v2制作.mp4档案时，如果你要使用的Audio编码格式是AAC，那么你就需要使用MP4SetTrackESConfiguration这个函式来设定解码需要的资料。在网路上看到的例子都是以FAAC编码为居多，大多都可以参考需要的设定，设定MP4SetTrackESConfiguration的方式，都是先利用FAAC里的  faacEncGetDecoderSpecificInfo得到想要的资料，再传给 MP4SetTrackESConfiguration
             
             faacEncGetDecoderSpecificInfo 的程式碼如下，可以看出我們要的格式是
             
             5 bits | 4 bits | 4 bits | 3 bits
             第一欄 第二欄 第三欄 第四欄
             
             第一欄：AAC Object Type
             第二欄：Sample Rate Index
             第三欄：Channel Number
             第四欄：Don't care，設 0
    
    // AAC object types
#define MAIN 1
#define LOW  2
#define SSR  3
#define LTP  4
    
    // Returns the sample rate index
    int GetSRIndex(unsigned int sampleRate)
    {
           if (92017 <= sampleRate) return 0;
           if (75132 <= sampleRate) return 1;
           if (55426 <= sampleRate) return 2;
           if (46009 <= sampleRate) return 3;
           if (37566 <= sampleRate) return 4;
           if (27713 <= sampleRate) return 5;
           if (23004 <= sampleRate) return 6;
           if (18783 <= sampleRate) return 7;
           if (13856 <= sampleRate) return 8;
           if (11502 <= sampleRate) return 9;
           if (9391 <= sampleRate) return 10;
        
           return 11;
    }
    
    現在，對於你自己要設定的參數值，就知道要怎麼設了吧！舉個例子，我使用的 AAC 是 LOW，44100 hz，Stereo，那麼從上面的資料來看
    
    第一欄：00010
    第二欄：0100
    第三欄：0010
    第四欄：000
    
    合起來： 00010010 00010000 ＝＞ 0x12 0x10
    原文：https://blog.csdn.net/tanningzhong/article/details/77527692
             */
            uint32_t aacConfigSize = 2;
            int8_t result[2] = {0};
            getESConfig(2, audioSampleRate, audioChannel, result);
            
            MP4SetTrackESConfiguration(m_mp4FHandle,m_aTrackId,(uint8_t*)result,(uint32_t)aacConfigSize);
            
        }
            break;
        default:
            break;
    }
    
    //-------------------------------------------------------------------------------------
}

//返回读了多少字节
static int ReadOneNaluFromBuf(const unsigned char *buffer,
                              unsigned int nBufferSize,
                              unsigned int offSet,
                              MP4ENC_NaluUnit &nalu)
{
    unsigned int i = offSet;
    while(i < nBufferSize)
    {
        if(buffer[i++] == 0x00 && buffer[i] == 0x00 && buffer[i+1] == 0x00 && buffer[i+2] == 0x01)
        {
            unsigned int pos = i+3;
            unsigned int iEnd = i+3;
            unsigned int posEnd = 0;
            while (pos < nBufferSize)
            {
                if(buffer[pos++] == 0x00 && buffer[pos] == 0x00 && buffer[pos+1] == 0x00 && buffer[pos+2] == 0x01)
                {
                    posEnd = pos+3;
                    break;
                }
                posEnd = pos;
            }
            if(posEnd == nBufferSize)
            {
                nalu.frameLen = posEnd-iEnd;
            }
            else
            {
                nalu.frameLen = (posEnd - 4) - iEnd;
            }

            nalu.frameType = buffer[iEnd]&0x1f;
            nalu.pframeBuf = (unsigned char*)&buffer[iEnd];
            return (nalu.frameLen+iEnd-offSet);
        }
    }

    return 0;
}


int CMp4Encoder::WriteVideoTrack(BYTE* pframeBuf,int frameSize)
{
    int offset = 0, len = 0;
    MP4ENC_NaluUnit nalu;

    while ((len = ReadOneNaluFromBuf((const unsigned char*)pframeBuf, frameSize, offset, nalu)))
    {
        
        if(nalu.frameType == 0x07)  //sps
        {
            if(m_bGetSpsSlice == false)
            {
                m_vTrackId = MP4AddH264VideoTrack(m_mp4FHandle,
                                                  m_vTimeScale,
                                                  m_vTimeScale/m_vFrateR,
                                                  m_vWidth,
                                                  m_vHeight,
                                                  nalu.pframeBuf[1],
                                                  nalu.pframeBuf[2],
                                                  nalu.pframeBuf[3],
                                                  3);
                if(m_vTrackId == MP4_INVALID_TRACK_ID)
                {
                    printf("add viedo trake failed.\n");
                    return -1;
                }
                
                
                MP4SetVideoProfileLevel(m_mp4FHandle, 1);
                MP4AddH264SequenceParameterSet(m_mp4FHandle, m_vTrackId, nalu.pframeBuf, nalu.frameLen);
                
                m_bGetSpsSlice = true;
            }
            

        }
        else if (nalu.frameType == 0x08) //pps
        {
            if(m_bGetPpsSlice == false)
            {
                MP4AddH264PictureParameterSet(m_mp4FHandle, m_vTrackId, nalu.pframeBuf, nalu.frameLen);
                m_bGetPpsSlice = true;
                
            }
            
        }
        else if((nalu.frameType != 0x06) && (nalu.frameType != 0x0d))
        {
            if((m_vTrackId != MP4_INVALID_TRACK_ID) && m_bGetSpsSlice && m_bGetPpsSlice && m_bRecord)
            {
                int datalen = nalu.frameLen + 4;
                BYTE *data = new BYTE[datalen];
                
                data[0] = nalu.frameLen >> 24;
                data[1] = nalu.frameLen >> 16;
                data[2] = nalu.frameLen >> 8;
                data[3] = nalu.frameLen & 0xff;
                
                memcpy(data+4, nalu.pframeBuf, nalu.frameLen);

                if(!MP4WriteSample(m_mp4FHandle, m_vTrackId, (const uint8_t*)data, datalen,m_vTimeScale/m_vFrateR))
                {
                    printf("write a viedo failed\n");
                    delete []data;

                    return -1;
                }
                m_bGetIFrame = true;
                
                delete []data;
            }

        }
        
        offset += len;
        
    }
    
    return offset;
}

int CMp4Encoder::WriteH264SPS(unsigned char* pBuf,int len)
{
    m_vTrackId = MP4AddH264VideoTrack(m_mp4FHandle,
                                      m_vTimeScale,
                                      m_vTimeScale/m_vFrateR,
                                      m_vWidth,
                                      m_vHeight,
                                      pBuf[1],
                                      pBuf[2],
                                      pBuf[3],
                                      3);
    if(m_vTrackId == MP4_INVALID_TRACK_ID)
    {
        printf("add viedo trake failed.\n");
        return -1;
    }
    
    MP4SetVideoProfileLevel(m_mp4FHandle, 1);
    MP4AddH264SequenceParameterSet(m_mp4FHandle, m_vTrackId, pBuf, len);
    
    m_bGetSpsSlice = true;
    return 0;
}

int CMp4Encoder::WriteH264PPS(unsigned char* pBuf,int len)
{
    MP4AddH264PictureParameterSet(m_mp4FHandle, m_vTrackId, pBuf, len);
    m_bGetPpsSlice = true;
    
    return 0;
}


int CMp4Encoder::WriteVideoTrack(BYTE* pframeBuf,int frameSize,unsigned char **ppsBuff,int *ppsLen,unsigned char **spsBuff,int *spsLen)
{
    int offset = 0, len = 0;
    MP4ENC_NaluUnit nalu;
    
    while ((len = ReadOneNaluFromBuf((const unsigned char*)pframeBuf, frameSize, offset, nalu)))
    {
        if(m_bRecord)
        {
            if(nalu.frameType == 0x07)  //sps
            {
                if(m_bGetSpsSlice == false)
                {
                    m_vTrackId = MP4AddH264VideoTrack(m_mp4FHandle,
                                                      m_vTimeScale,
                                                      m_vTimeScale/m_vFrateR,
                                                      m_vWidth,
                                                      m_vHeight,
                                                      nalu.pframeBuf[1],
                                                      nalu.pframeBuf[2],
                                                      nalu.pframeBuf[3],
                                                      3);
                    if(m_vTrackId == MP4_INVALID_TRACK_ID)
                    {
                        printf("add viedo trake failed.\n");
                        return -1;
                    }
                    
                    MP4SetVideoProfileLevel(m_mp4FHandle, 1);
                    MP4AddH264SequenceParameterSet(m_mp4FHandle, m_vTrackId, nalu.pframeBuf, nalu.frameLen);
                    
                    m_bGetSpsSlice = true;
                }
            }
            else if (nalu.frameType == 0x08) //pps
            {
                if(m_bGetPpsSlice == false)
                {
                    MP4AddH264PictureParameterSet(m_mp4FHandle, m_vTrackId, nalu.pframeBuf, nalu.frameLen);
                    m_bGetPpsSlice = true;
                }
            }
            else if((nalu.frameType != 0x06) && (nalu.frameType != 0x0d))
            {
                if((m_vTrackId != MP4_INVALID_TRACK_ID) && m_bGetSpsSlice && m_bGetPpsSlice)
                {
                    int datalen = nalu.frameLen + 4;
                    BYTE *data = new BYTE[datalen];
                    
                    data[0] = nalu.frameLen >> 24;
                    data[1] = nalu.frameLen >> 16;
                    data[2] = nalu.frameLen >> 8;
                    data[3] = nalu.frameLen & 0xff;
                    
                    memcpy(data+4, nalu.pframeBuf, nalu.frameLen);
                    
                    if(!MP4WriteSample(m_mp4FHandle, m_vTrackId, (const uint8_t*)data, datalen,m_vTimeScale/m_vFrateR))
                    {
                        printf("write a viedo failed\n");
                        delete []data;
                        
                        return -1;
                    }
                    m_bGetIFrame = true;
                    
                    delete []data;
                }
                
            }
        }
        else
        {
            if(nalu.frameType == 0x07)  //sps
            {
                *spsBuff = (unsigned char *)malloc(nalu.frameLen);
                memcpy(*spsBuff, nalu.pframeBuf, nalu.frameLen);
                memcpy(spsLen, &nalu.frameLen, sizeof(nalu.frameLen));
            }
            else if (nalu.frameType == 0x08) //pps
            {
                *ppsBuff = (unsigned char *)malloc(nalu.frameLen);
                memcpy(*ppsBuff, nalu.pframeBuf, nalu.frameLen);
                memcpy(ppsLen, &nalu.frameLen, sizeof(nalu.frameLen));
            }
        }
        
        offset += len;
        
    }
    
    return offset;
}


//添加音频数据
int CMp4Encoder::WriteAudioTrack(BYTE* _aacData,int _aacSize)
{
    if(m_aTrackId == MP4_INVALID_TRACK_ID)
    {
        return -1;
    }
    
    if (!m_bGetIFrame)
    {
        return -1;
    }
    
    if(!m_bRecord)
    {
        return -1;
    }
    
    if(m_audioFormat == WAVE_FORMAT_AAC)
    {
         bool result = MP4WriteSample(m_mp4FHandle, m_aTrackId,(const uint8_t*) _aacData+7, _aacSize-7 ,1024, 0, 1);
        if (result == true) {
            printf("add success!\n");
        }else {
            printf("add failed!\n");
        }
    }
    else if (m_audioFormat == WAVE_FORMAT_G711)
    {
        MP4WriteSample(m_mp4FHandle, m_aTrackId,(const uint8_t*) _aacData, _aacSize ,MP4_INVALID_DURATION, 0, 1);
    }
   
    
    return _aacSize;
}



void CMp4Encoder::CloseMp4Encoder()
{
    if(m_mp4FHandle)
    {
        MP4Close(m_mp4FHandle);  
        m_mp4FHandle = NULL;  
    }
}


