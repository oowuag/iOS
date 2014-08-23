#ifndef DATAQUEUE_H
#define DATAQUEUE_H

/**
* @class DataQueue
* 
* common base class for queue
*/
template <typename Elem, unsigned short SIZE>
class DataQueue
{
public:
    // Constructor
	DataQueue()
    :m_pData(NULL)
    ,m_wWrite(0)
    ,m_wRead(0)
    ,m_wTotalSize(SIZE)
    ,m_wNumber(0)
    {
        if (0 == m_wTotalSize){
            m_wTotalSize = 1;
        }
        m_pData     = new Elem[m_wTotalSize];
        //init data
        memset(m_pData, 0, sizeof(Elem)*m_wTotalSize);
    }
      

    // Destructor
	~DataQueue()
    {
        delete[] m_pData;
    }

    // push data to queue
	bool push(Elem& Item)
    {
		// deque buffer full
		if ((m_wTotalSize == m_wNumber) && (m_wWrite == m_wRead))
        {
            // forward read ptr, abandon old data
			m_wRead = (m_wRead + 1) % m_wTotalSize;
        }

        // copy data
        memcpy(&m_pData[m_wWrite], &Item, sizeof(Elem));

        // iterate write pointer
		m_wWrite = (m_wWrite + 1) % m_wTotalSize;
		m_wNumber++;
        if (m_wNumber > m_wTotalSize) {
            m_wNumber = m_wTotalSize;
        }

        return true;
    }

    // pop data from queue
	bool pop(Elem& Item)
    {
        // have new buffer data or not
		if (0 == m_wNumber) {
            // failed
            return false;
        }

        // copy data
        memcpy(&Item, &m_pData[m_wRead], sizeof(Elem));

        // iterate read pointer
        m_wRead = (m_wRead + 1) % m_wTotalSize;
        m_wNumber--;

        return true;
    }

    // get number of elem
	unsigned short number( )
    {
        return m_wNumber;
    }

    // check if the queue is empty
    bool isEmpty( )
    {
        // check size
		if (0 == m_wNumber)
		{
            return true;
        }
        return false;
    }

    // get Data Of Index

    bool getDataOfIndex(unsigned short wIndex,Elem& rElem)
    {
        if (wIndex >= m_wTotalSize)
        {
            return false;
        }
        rElem = m_pData[wIndex];
        return true;
    }

private:
	Elem*				m_pData;				//The actual data array
	unsigned short		m_wWrite;				//Numbered location of the write
	unsigned short		m_wRead;				//Numbered location of the read
	unsigned short		m_wTotalSize;			//max elements size
    unsigned short		m_wNumber;				//current number
};

#endif //DATAQUEUE_H