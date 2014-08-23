

const char PRO_VERSION = 0x01;
const short SENSOR_DATASIZE = 16;


bool EncodeData(const float pInData[], const int nInSize, unsigned char *pOutBuff, int *pnOutSize);
bool DecodeData(const unsigned char *pInBuff, const int nInSize, float pOutData[], int *pnOutSize);

