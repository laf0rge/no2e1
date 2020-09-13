CORE := no2e1

RTL_SRCS_no2e1 = $(addprefix rtl/, \
	e1_crc4.v \
	e1_rx_clock_recovery.v \
	e1_rx_deframer.v \
	e1_rx_filter.v \
	e1_rx_phy.v \
	e1_rx_liu.v \
	e1_rx.v \
	e1_tx_framer.v \
	e1_tx_phy.v \
	e1_tx_liu.v \
	e1_tx.v \
	e1_wb_rx.v \
	e1_wb_tx.v \
	e1_wb.v \
	hdb3_dec.v \
	hdb3_enc.v \
)

TESTBENCHES_no2e1 := \
	e1_crc4_tb \
	e1_tb \
	e1_tx_framer_tb \
	hdb3_tb \

include $(NO2BUILD_DIR)/core-magic.mk
