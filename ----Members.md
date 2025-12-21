# **----Members** 





## **---------4-----# of Enhanced Services Medicaid Members**





-- Enhanced Services Medicaid Members (YTD)

-- Unique CINs with any Enhanced Flag = 'Y' since Jan 1, 2025



SELECT COUNT(DISTINCT mbrID)

FROM dbo.nyec\_esmf

WHERE 

&nbsp;   (

&nbsp;       \[EPOPHighUtilizer]     = 'Y'

&nbsp;    OR \[EPOPHHEnrolled]       = 'Y'

&nbsp;    OR \[EPOPOther]            = 'Y'

&nbsp;    OR \[EPOPPregPostpartum]   = 'Y'

&nbsp;    OR \[EPOPUnder18Nutrition] = 'Y'

&nbsp;    OR \[EPOPUnder18]          = 'Y'

&nbsp;    OR \[EPOPAdultCJ]          = 'Y'

&nbsp;    OR \[EPOPIDD]              = 'Y'    

&nbsp;   )

&nbsp;













## **-----# of Medicaid Members**

----Total count of Unique CINS YTD from MEF file---





-- YTD Unique Members (Network)

SELECT COUNT(DISTINCT CIN) AS YTD\_Unique\_Members

FROM dbo.nyec\_mef ;











## **-----# of Medicaid Members**

## 



---Total count of Current Medicaid Mmebers MEF file---

-- Pick latest 2025 file by first 8 digits (YYYYMMDD), prioritizing month then day

WITH files AS (

&nbsp;   SELECT

&nbsp;       SourceFileName,

&nbsp;       pos8 = PATINDEX('%\[0-9]\[0-9]\[0-9]\[0-9]\[0-9]\[0-9]\[0-9]\[0-9]%', SourceFileName)

&nbsp;   FROM dbo.nyec\_mef

),

dated AS (

&nbsp;   SELECT

&nbsp;       f.SourceFileName,

&nbsp;       yyyymmdd = SUBSTRING(f.SourceFileName, f.pos8, 8),

&nbsp;       yy = SUBSTRING(f.SourceFileName, f.pos8 + 0, 4),  -- YYYY

&nbsp;       mm = SUBSTRING(f.SourceFileName, f.pos8 + 4, 2),  -- MM

&nbsp;       dd = SUBSTRING(f.SourceFileName, f.pos8 + 6, 2)   -- DD

&nbsp;   FROM files f

&nbsp;   WHERE f.pos8 > 0

),

only\_2025 AS (

&nbsp;   SELECT \*

&nbsp;   FROM dated

&nbsp;   WHERE yy = '2025'

),

latest AS (

&nbsp;   SELECT TOP (1) SourceFileName

&nbsp;   FROM only\_2025

&nbsp;   ORDER BY mm DESC, dd DESC   -- choose largest month, then largest day

)

SELECT COUNT(DISTINCT m.MbrID) AS Current\_Members\_from\_Selected\_File

FROM dbo.nyec\_mef m

JOIN latest lf

&nbsp; ON m.SourceFileName = lf.SourceFileName;



























