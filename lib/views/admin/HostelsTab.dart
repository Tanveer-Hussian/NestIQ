import 'package:flutter/material.dart';
import 'package:fyp/controllers/HostelController.dart' show HostelController;
import 'package:fyp/views/admin/widgets/ApprovedHostelsList.dart';
import 'package:fyp/views/admin/widgets/SegmentButton.dart';
import 'package:get/get.dart';


class HostelsTab extends StatefulWidget {

  final HostelController hostelCtrl;
  const HostelsTab({required this.hostelCtrl});

  @override
  State<HostelsTab> createState() => HostelsTabState();
}


class HostelsTabState extends State<HostelsTab> {
  
  int _subTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentButton(
                  label: 'Pending',
                  isSelected: _subTabIndex == 0,
                  onTap: () => setState(() => _subTabIndex = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SegmentButton(
                  label: 'All Hostels',
                  isSelected: _subTabIndex == 1,
                  onTap: () => setState(() => _subTabIndex = 1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            final hostels = _subTabIndex == 0
                ? widget.hostelCtrl.pendingHostels.toList()  
                : widget.hostelCtrl.allHostels.toList();      

            return HostelApprovalList(
              hostels: hostels,
              emptyMessage: _subTabIndex == 0
                  ? 'No pending listings ✅'
                  : 'No hostels registered.',
              hostelCtrl: widget.hostelCtrl,
              showActions: _subTabIndex == 0,
            );
          }),
        ),
      ],
    );
  }
}

