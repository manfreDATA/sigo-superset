
// ECharts Custom Plugins from SIGO Superset
import { EchartsDatasetLinkPlugin } from 'superset-plugin-chart-echarts-extras';
import { EchartsDatasetSeriesLayoutByPlugin } from 'superset-plugin-chart-echarts-extras';
import { EchartsBarYStackPlugin } from 'superset-plugin-chart-echarts-extras';
import { EchartsBarNegativePlugin } from 'superset-plugin-chart-echarts-extras';
import { EchartsMatrixMiniBarGeoPlugin } from 'superset-plugin-chart-echarts-extras';

new EchartsDatasetLinkPlugin().configure({ key: 'echarts_dataset_link' }).register();
new EchartsDatasetSeriesLayoutByPlugin().configure({ key: 'echarts_dataset_series_layout_by' }).register();
new EchartsBarYStackPlugin().configure({ key: 'echarts_bar_y_stack' }).register();
new EchartsBarNegativePlugin().configure({ key: 'echarts_bar_negative' }).register();
new EchartsMatrixMiniBarGeoPlugin().configure({ key: 'echarts_matrix_mini_bar_geo' }).register();
