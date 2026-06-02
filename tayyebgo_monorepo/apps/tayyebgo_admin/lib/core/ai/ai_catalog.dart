import 'package:tayyebgo_admin/core/ai/agent_tool.dart';
import 'package:tayyebgo_admin/core/ai/tools/read_tools.dart';
import 'package:tayyebgo_admin/core/ai/tools/create_tools.dart';
import 'package:tayyebgo_admin/core/ai/tools/edit_tools.dart';
import 'package:tayyebgo_admin/core/ai/tools/analyze_tools.dart';
import 'package:tayyebgo_admin/core/ai/tools/recommend_tools.dart';

class AiCatalog {
  static final AiCatalog instance = AiCatalog._();
  AiCatalog._() {
    _registerAll();
  }

  final AgentToolRegistry registry = AgentToolRegistry();

  void _registerAll() {
    // Read
    registry.register(ReadStoreTool());
    registry.register(ListStoresTool());
    registry.register(ListOrdersTool());
    registry.register(ListDriversTool());
    registry.register(ListCustomersTool());
    registry.register(ReadRevenueTool());
    registry.register(ListNotificationsTool());
    registry.register(ReadSettingsTool());

    // Create
    registry.register(CreateStoreTool());
    registry.register(CreateCategoryTool());
    registry.register(CreatePromotionTool());
    registry.register(CreateCouponTool());
    registry.register(CreateCampaignTool());
    registry.register(CreateNotificationTool());
    registry.register(GenerateReportTool());

    // Edit
    registry.register(EditStoreDesignTool());
    registry.register(EditStoreSettingsTool());
    registry.register(EditDeliverySettingsTool());
    registry.register(EditPromotionTool());
    registry.register(EditCategoryTool());

    // Analyze
    registry.register(AnalyzeRevenueTool());
    registry.register(AnalyzeDriverPerformanceTool());
    registry.register(AnalyzeStorePerformanceTool());
    registry.register(AnalyzeCustomerRetentionTool());
    registry.register(AnalyzeOrderTrendsTool());

    // Recommend
    registry.register(RecommendOperationsTool());
    registry.register(RecommendDriverAllocationTool());
    registry.register(RecommendMarketingTool());
    registry.register(RecommendRevenueTool());
  }
}
