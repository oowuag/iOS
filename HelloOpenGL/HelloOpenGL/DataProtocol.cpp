//#ifndef __cplusplus
//#error "compiled as C++"
//#endif


#include <stdio.h>
#include <string.h>

#include "DataProtocol.h"

typedef unsigned char BYTE;
typedef short SHORT;

const int SND_BUFFER_MAXSIZE = 1024;
char szSndBuffer[SND_BUFFER_MAXSIZE];
int nSndBufferCnt = 0;


// encode func--------------------------------------------------
// save byte data
void EncodeByteData(BYTE data)
{
	// check buffer size
    if (nSndBufferCnt >= SND_BUFFER_MAXSIZE)  {
		printf("EncodeByteData size overflow!\n");
		return;
    }
	// set buffer
    szSndBuffer[nSndBufferCnt++] = data;
}

// save block data invert byte sequence
void EncodeBlockData(BYTE *data, SHORT len)
{
    data += len;

	// save block data
    while (len)  {
        data--;
		// save byte data
        EncodeByteData(*data);
		// size decrease
        len--;
    }
}

// calculate checksum
void CheckSum(BYTE *a, BYTE *b, SHORT c)
{
    for( ; c>0; c--,b++)  {
		*a = *a ^ *b;
    }
}


//decode func-------------------------------------------------
// check checksum
bool CheckCheckSum(const BYTE *rsd, const int DataLen)
{
	BYTE  check_sum = 0;
	for (int cnt = 0; cnt < DataLen; cnt++)
	{
		check_sum ^= rsd[cnt];
	}

	if (check_sum)
		return false;
	else 
		return true;
}
// byte 2 float Big Endian -> Little Endian
float Byte2Float(const BYTE *data)
{
	int     j;
	float   i;
	BYTE    *ip;

	ip = (BYTE *)&i;
	for (j = 3 ; j >= 0 ; j--) {
		*ip++ = data[j];
	}
	return(i);
}


//----------------------------------------------------------------------------
// encode
bool EncodeData(const float pInData[], const int nInSize, unsigned char *pOutBuff, int *pnOutSize)
{
	if (pInData == NULL || pOutBuff == NULL || pnOutSize == NULL)
	{
		printf("Encode data pointer NULL!\n");
		return false;
	}
	if (nInSize <=0 || nInSize > 255)
	{
		printf("Encode nInSize data Error!\n");
		return false;
	}

	memset(szSndBuffer, 0, sizeof(szSndBuffer));
	nSndBufferCnt = 0;


	BYTE	ck_sum = 0; // checksum

	// start--
	EncodeByteData(0x10);
	ck_sum ^= 0x10;

	// version
    EncodeByteData(PRO_VERSION);
    ck_sum ^= PRO_VERSION;

	// ID
    EncodeByteData(0x01);
    ck_sum ^= 0x01;

	for(int i=0; i<nInSize; i++)
	{
		// sensor data
		EncodeBlockData((BYTE *)&pInData[i], 4);
		CheckSum(&ck_sum, (BYTE *)&pInData[i], 4);
	}

	// check end first
	ck_sum ^= 0x03;
	// checksum
    EncodeByteData(ck_sum);

	// end---
    EncodeByteData(0x03);


	// output
	*pnOutSize = nSndBufferCnt;
	memcpy(pOutBuff, szSndBuffer, nSndBufferCnt);

	return true;
}

//----------------------------------------------------------------------------
// decode
bool DecodeData(const unsigned char *pInBuff, const int nInSize, float pOutData[], int *pnOutSize)
{

	if (pInBuff == NULL || pOutData == NULL || pnOutSize == NULL)
	{
		printf("Decode data pointer NULL!\n");
		return false;
	}
	if (nInSize <=0 || nInSize > SND_BUFFER_MAXSIZE)
	{
		printf("Decode nInSize data Error!\n");
		return false;
	}

	// check data size
	if (nInSize != 69) {
		// data size check failed
		printf("Decode DataSizeCheck Error!\n");
		return false;
	}

	// checksum
	if (CheckCheckSum(pInBuff, nInSize) == false) //abando first and last one
	{
		// checksum failed
		printf("Decode Checksum Error!\n");
		return false;
	}

	*pnOutSize = SENSOR_DATASIZE;

	int nRsdP = 0;

	// start
	BYTE byStart	= pInBuff[nRsdP++];

	// verstion
	BYTE byVersion	= pInBuff[nRsdP++];

	// id
	BYTE byId		= pInBuff[nRsdP++];

	for(int i=0; i<SENSOR_DATASIZE; i++)
	{
		// sensor data
		pOutData[i]	= Byte2Float(&pInBuff[nRsdP]);
		nRsdP += 4;
	}

	// checksum
	BYTE byCheckSum	= pInBuff[nRsdP++];

	// end
	BYTE byEnd		= pInBuff[nRsdP++];

	return true;
}


bool test()
{
	// encode ------------------------------
	const int DATA_SIZE = SENSOR_DATASIZE;
	float fSensorData[DATA_SIZE];
	BYTE pSndBuff[256];
	int nSndSize = 0;
	memset(pSndBuff, 0 , sizeof(pSndBuff));
	for (int i=0; i<SENSOR_DATASIZE; i++)
	{
		fSensorData[i] = i + 0.1;
	}

	bool bSndOk = EncodeData(fSensorData, DATA_SIZE, pSndBuff, &nSndSize);
	if(!bSndOk)
	{
		printf("EncodeData Error!\n");
		return false;
	}


	// decode ------------------------------
	float fRcvSensorData[DATA_SIZE];
	int nRcvSize = 0;
	memset(fRcvSensorData, 0, sizeof(fRcvSensorData));
	bool bRcvOk = DecodeData(pSndBuff, nSndSize, fRcvSensorData, &nRcvSize);
	if(!bRcvOk)
	{
		printf("DecodeData Error!\n");
		return false;
	}

	//ok
	printf("Data=%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f\n", 
		fRcvSensorData[0], fRcvSensorData[1], fRcvSensorData[2], fRcvSensorData[3], 
		fRcvSensorData[4], fRcvSensorData[5], fRcvSensorData[6], fRcvSensorData[7], 
		fRcvSensorData[8], fRcvSensorData[9], fRcvSensorData[10], fRcvSensorData[11], 
		fRcvSensorData[12], fRcvSensorData[13], fRcvSensorData[14], fRcvSensorData[15]);
	
	return true;
}