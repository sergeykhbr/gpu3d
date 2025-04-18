# MIPT University
# sergeykhbr@gmail.com
#

include src.mk

TIMESCALE=1ns/10ps
BENCH=board
CYCLES=30000

INC+=+incdir+${VIPS_HOME}/pcie_rootport
INC+=+incdir+${PRJ_ROOT}
# Remove vhdl after updating HDMI PHY
VHDL_PARAMS=-64 -v93 -smartorder
VLOG_PARAMS_TB=-64 -sv -work work
ELAB_PARAMS=-64 -v93 -namemap_mixgen -timescale ${TIMESCALE} -access +rwc
SIM_OPTS = -64 -input ./ncsim_settings work.${BENCH} +cycles=${CYCLES}

GLOBAL_DEFINE+=+define+TARGET_KC705

#================================================================================================


#================================================================================================
# Slurm controls
#================================================================================================

#SRUN=@srun --pty -c 12 --exclude=node-b01,node-b02
SRUN=@srun --pty -c 4

prep:
	@mkdir -p work

clr_logs:
	@echo "==========================================================================================="
	@echo " START CLEAR LOGS: "
	@echo "==========================================================================================="
	@rm -f *.log
	@rm -f *.log.tmp
	@rm -f ./*.dis ./*.ecs*
	@rm -f ./*.errmsg* ./*.mix


comp: prep clr_logs
	@echo "==========================================================================================="
	@echo " START COMPILATION: "
	@echo "==========================================================================================="
	${SRUN} xmvlog ${VLOG_PARAMS_TB} ${INC} ${GLOBAL_DEFINE} -f ${LISTS_HOME}/techmap_pcie_kc705.f
	${SRUN} xmvlog ${VLOG_PARAMS_TB} ${INC} ${GLOBAL_DEFINE} -f board.f

build: comp
	@echo "==========================================================================================="
	@echo " START BUILD: "
	@echo "==========================================================================================="
	${SRUN} xmelab ${ELAB_PARAMS} ${BENCH}

gui:clr_logs
	@echo "==========================================================================================="
	@echo " START GUI: "
	@echo "==========================================================================================="
	${SRUN} xmsim ${SIM_OPTS} -gui

gui_full: clean build gui

mce_flow: prep clr_logs
	@srun --pty -c 12 --exclude=node-b01,node-b02 xrun -gui -mce \
	-timescale 1ns/10ps \
	-access -rwc \
    	${VLOG_PARAMS_TB} ${INC} ${GLOBAL_DEFINE} \
	-f ${LISTS_HOME}/techmap_pcie_kc705.f \
	-f board.f \
	-top board \
	-mce_top board.tt

clean:
	@echo "==========================================================================================="
	@echo " START CLEAN: "
	@echo "==========================================================================================="
	@rm -f *.log *.key *.diag *.err
	@rm -rf work
	@rm -rf waves* INCA_* .simvision
	@rm -f ./*.tmp
	@rm -f ./*.dis ./*.ecs*
	@rm -f ./*.errmsg* ./*.mix
	@rm -f ./*.X
	@rm -rf ./*.shm
	@rm -rf ./xcelium.d
	@rm -rf ./mcesim.run

